package services

import (
	"app/db"
	"app/db/models"
	"errors"
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v4"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type UpdateServerInput struct {
	Name       string      `json:"name"`
	Visibility string      `json:"visibility"`
	MediaID    uuid.UUID   `json:"media_id"`
	TagIDs     []uuid.UUID `json:"tag_ids"`
}

type BanUserInput struct {
	Reason   string `json:"reason" binding:"required"`
	Duration int    `json:"duration" binding:"required"`
}

func GetAllServers() gin.HandlerFunc {
	return func(c *gin.Context) {
		claims, exists := c.Get("jwt_claims")
		if !exists {
			handleError(c, http.StatusUnauthorized, "Erreur lors de la récupération des revendications JWT")
			return
		}

		jwtClaims, ok := claims.(jwt.MapClaims)
		if !ok {
			handleError(c, http.StatusInternalServerError, "Erreur lors de l'extraction des revendications JWT")
			return
		}

		userIDStr, ok := jwtClaims["jti"].(string)
		if !ok {
			handleError(c, http.StatusInternalServerError, "Erreur lors de la récupération de l'ID utilisateur")
			return
		}

		userID, err := uuid.Parse(userIDStr)
		if err != nil {
			handleError(c, http.StatusInternalServerError, "Erreur lors de la conversion de l'ID utilisateur")
			return
		}

		var servers []models.Server

		if err := db.GetDB().
			Table("servers").
			Where("id NOT IN (SELECT server_id FROM on_servers WHERE user_id = ?)", userID).
			Where("deleted_at IS NULL").
			Preload("Media").
			Preload("Tags").
			Find(&servers).Error; err != nil {
			handleError(c, http.StatusInternalServerError, "Erreur lors de la récupération des serveurs")
			return
		}

		c.JSON(http.StatusOK, servers)
	}
}

func GetServerBans() gin.HandlerFunc {
	return func(c *gin.Context) {
		serverID := c.Param("id")
		if serverID == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Server ID is required"})
			return
		}

		var bans []models.Ban
		result := db.GetDB().Preload("User", func(db *gorm.DB) *gorm.DB {
			return db.Select("id, pseudo, email, role, profile")
		}).Preload("Server", func(db *gorm.DB) *gorm.DB {
			return db.Select("id, name, visibility, user_id")
		}).Preload("BannedBy", func(db *gorm.DB) *gorm.DB {
			return db.Select("id, pseudo, email, role, profile")
		}).Where("server_id = ?", serverID).Find(&bans)

		if result.Error != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
			return
		}

		c.JSON(http.StatusOK, bans)
	}
}

func BanUser() gin.HandlerFunc {
	return func(c *gin.Context) {
		serverID := c.Param("id")
		userID := c.Param("userID")
		var input BanUserInput

		if err := c.ShouldBindJSON(&input); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		serverUUID, err := uuid.Parse(serverID)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid server ID"})
			return
		}

		userUUID, err := uuid.Parse(userID)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
			return
		}

		var onServer models.OnServer
		if err := db.GetDB().Where("server_id = ? AND user_id = ?", serverUUID, userUUID).First(&onServer).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "User is not a member of this server"})
			return
		}

		var server models.Server
		if err := db.GetDB().First(&server, "id = ?", serverUUID).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Server not found"})
			return
		}

		var existingBan models.Ban
		if err := db.GetDB().Where("server_id = ? AND user_id = ?", serverUUID, userUUID).First(&existingBan).Error; err == nil {
			c.JSON(http.StatusConflict, gin.H{"error": "User is already banned from this server"})
			return
		}

		claims, exists := c.Get("jwt_claims")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
			return
		}
		jwtClaims := claims.(jwt.MapClaims)
		bannedByIDStr := jwtClaims["jti"].(string)
		bannedByID, err := uuid.Parse(bannedByIDStr)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to parse the user ID from JWT"})
			return
		}

		if server.UserID != bannedByID {
			c.JSON(http.StatusForbidden, gin.H{"error": "Only the server creator can ban users"})
			return
		}

		tx := db.GetDB().Begin()

		ban := models.Ban{
			Reason:     input.Reason,
			Duration:   time.Now().AddDate(0, 0, input.Duration),
			UserID:     userUUID,
			ServerID:   serverUUID,
			BannedByID: bannedByID,
		}

		if err := tx.Create(&ban).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		if err := tx.Where("server_id = ? AND user_id = ?", serverUUID, userUUID).Delete(&models.OnServer{}).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		if err := tx.Commit().Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusOK, ban)
	}
}

func UnbanUser() gin.HandlerFunc {
	return func(c *gin.Context) {
		serverID := c.Param("id")
		userID := c.Param("userID")

		serverUUID, err := uuid.Parse(serverID)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid server ID"})
			return
		}

		userUUID, err := uuid.Parse(userID)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
			return
		}

		var ban models.Ban
		if err := db.GetDB().Where("server_id = ? AND user_id = ?", serverUUID, userUUID).First(&ban).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Ban not found"})
			return
		}

		if err := db.GetDB().Delete(&ban).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to unban user"})
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "User unbanned"})
	}
}

func GetServerByID() gin.HandlerFunc {
	return func(c *gin.Context) {
		serverIDStr := c.Param("id")
		serverID, err := uuid.Parse(serverIDStr)
		if err != nil {
			handleError(c, http.StatusBadRequest, "ID de serveur invalide")
			return
		}

		var server models.Server
		if err := db.GetDB().Preload("Media").Preload("Tags").First(&server, serverID).Error; err != nil {
			handleError(c, http.StatusNotFound, "Serveur non trouvé")
			return
		}

		c.JSON(http.StatusOK, server)
	}
}

func SearchServerByName() gin.HandlerFunc {
	return func(c *gin.Context) {
		name := c.Query("name")
		if name == "" {
			handleError(c, http.StatusBadRequest, "Le nom du serveur est requis")
			return
		}

		var servers []models.Server
		if err := db.GetDB().Where("name ILIKE ?", "%"+name+"%").Preload("Media").Preload("Tags").Find(&servers).Error; err != nil {
			handleError(c, http.StatusInternalServerError, "Erreur lors de la recherche du serveur")
			return
		}

		c.JSON(http.StatusOK, servers)
	}
}

func NewServer() gin.HandlerFunc {
	return func(c *gin.Context) {
		var inputServer models.Server

		if err := c.ShouldBindJSON(&inputServer); err != nil {
			handleError(c, http.StatusBadRequest, "Erreur lors de la liaison des données JSON")
			return
		}

		if inputServer.Name == "" {
			handleError(c, http.StatusBadRequest, "Le nom du serveur est requis")
			return
		}

		if inputServer.Visibility == "" {
			handleError(c, http.StatusBadRequest, "La visibilité du serveur est requise")
			return
		}

		if inputServer.Visibility == "public" && len(inputServer.Tags) == 0 {
			handleError(c, http.StatusBadRequest, "Un tag est requis pour les serveurs publics")
			return
		}

		if inputServer.MediaID == uuid.Nil {
			var media models.Media
			if err := db.GetDB().Where("file_name = ?", "default.png").First(&media).Error; err != nil {
				handleError(c, http.StatusInternalServerError, "Erreur lors de la recherche du média par défaut")
				return
			}
			inputServer.MediaID = media.ID
		}

		claims, exists := c.Get("jwt_claims")
		if !exists {
			handleError(c, http.StatusUnauthorized, "Erreur lors de la récupération des revendications JWT")
			return
		}

		jwtClaims, ok := claims.(jwt.MapClaims)
		if !ok {
			handleError(c, http.StatusInternalServerError, "Erreur lors de l'extraction des revendications JWT")
			return
		}

		userIDStr, ok := jwtClaims["jti"].(string)
		if !ok {
			handleError(c, http.StatusInternalServerError, "Erreur lors de la récupération de l'ID utilisateur")
			return
		}

		userID, err := uuid.Parse(userIDStr)
		if err != nil {
			handleError(c, http.StatusInternalServerError, "Erreur lors de la conversion de l'ID utilisateur")
			return
		}

		inputServer.UserID = userID

		tx := db.GetDB().Begin()

		for _, tagID := range inputServer.Tags {
			var tag models.Tag
			if err := tx.First(&tag, tagID.ID).Error; err != nil {
				if errors.Is(err, gorm.ErrRecordNotFound) {
					tx.Rollback()
					handleError(c, http.StatusBadRequest, fmt.Sprintf("Le tag avec l'ID %d n'existe pas", tagID.ID))
					return
				} else {
					tx.Rollback()
					handleError(c, http.StatusInternalServerError, "Erreur lors de la recherche du tag")
					return
				}
			}
		}

		if err := tx.Create(&inputServer).Error; err != nil {
			tx.Rollback()
			handleError(c, http.StatusInternalServerError, "Erreur lors de la création du serveur")
			return
		}

		if err := tx.Preload("Media").First(&inputServer).Error; err != nil {
			tx.Rollback()
			handleError(c, http.StatusInternalServerError, "Erreur lors du préchargement du média")
			return
		}

		inputOnServer := models.OnServer{
			ServerID: inputServer.ID,
			UserID:   userID,
		}
		if err := tx.Create(&inputOnServer).Error; err != nil {
			tx.Rollback()
			handleError(c, http.StatusInternalServerError, "Erreur lors de la création de l'association serveur-utilisateur")
			return
		}

		inputRole := models.Role{
			ServerID: inputServer.ID,
			Label:    "membre",
		}
		if err := tx.Create(&inputRole).Error; err != nil {
			tx.Rollback()
			handleError(c, http.StatusInternalServerError, "Erreur lors de la création du rôle")
			return
		}

		inputRoleUser := models.RoleUser{
			RoleID: inputRole.ID,
			UserID: userID,
		}
		if err := tx.Create(&inputRoleUser).Error; err != nil {
			tx.Rollback()
			handleError(c, http.StatusInternalServerError, "Erreur lors de la création de l'association rôle-utilisateur")
			return
		}

		inputChannel := models.Channel{
			ServerID:   inputServer.ID,
			Name:       "général",
			Type:       "text",
			Permission: "all",
		}
		if err := tx.Create(&inputChannel).Error; err != nil {
			tx.Rollback()
			handleError(c, http.StatusInternalServerError, "Erreur lors de la création du canal")
			return
		}

		tx.Commit()

		c.JSON(http.StatusCreated, gin.H{"data": inputServer})
	}
}

func JoinServer() gin.HandlerFunc {
	return func(c *gin.Context) {
		serverIDStr := c.Param("id")
		serverID, err := uuid.Parse(serverIDStr)
		if err != nil {
			handleError(c, http.StatusBadRequest, "ID de serveur invalide")
			return
		}

		claims, exists := c.Get("jwt_claims")
		if !exists {
			handleError(c, http.StatusUnauthorized, "Erreur lors de la récupération des revendications JWT")
			return
		}

		jwtClaims, ok := claims.(jwt.MapClaims)
		if !ok {
			handleError(c, http.StatusInternalServerError, "Erreur lors de l'extraction des revendications JWT")
			return
		}

		userIDStr, ok := jwtClaims["jti"].(string)
		if !ok {
			handleError(c, http.StatusInternalServerError, "Erreur lors de la récupération de l'ID utilisateur")
			return
		}

		userID, err := uuid.Parse(userIDStr)
		if err != nil {
			handleError(c, http.StatusInternalServerError, "Erreur lors de la conversion de l'ID utilisateur")
			return
		}

		tx := db.GetDB().Begin()
		defer func() {
			if r := recover(); r != nil {
				tx.Rollback()
				handleError(c, http.StatusInternalServerError, "Erreur lors de la transaction.")
				return
			}
		}()

		var server models.Server
		if err := tx.First(&server, serverID).Error; err != nil {
			tx.Rollback()
			handleError(c, http.StatusBadRequest, "Le serveur n'existe pas.")
			return
		}

		var count int64
		if err := tx.Model(&models.OnServer{}).Where("server_id = ? AND user_id = ?", serverID, userID).Count(&count).Error; err != nil {
			tx.Rollback()
			handleError(c, http.StatusInternalServerError, "Erreur lors de la vérification de l'utilisateur sur le serveur.")
			return
		}
		if count > 0 {
			tx.Rollback()
			handleError(c, http.StatusBadRequest, "L'utilisateur est déjà sur le serveur.")
			return
		}

		onServer := models.OnServer{
			ServerID: serverID,
			UserID:   userID,
		}
		if err := tx.Create(&onServer).Error; err != nil {
			tx.Rollback()
			handleError(c, http.StatusInternalServerError, "Erreur lors de la création de l'association serveur-utilisateur.")
			return
		}

		var role models.Role
		if err := tx.Where("server_id = ? AND label = ?", serverID, "membre").First(&role).Error; err != nil {
			tx.Rollback()
			handleError(c, http.StatusInternalServerError, "Erreur lors de la récupération du rôle.")
			return
		}

		roleUser := models.RoleUser{
			RoleID: role.ID,
			UserID: userID,
		}
		if err := tx.Create(&roleUser).Error; err != nil {
			tx.Rollback()
			handleError(c, http.StatusInternalServerError, "Erreur lors de l'attribution du rôle à l'utilisateur.")
			return
		}

		tx.Commit()

		c.JSON(http.StatusOK, gin.H{"data": onServer})
	}
}

func GetPublicAvailableServers() gin.HandlerFunc {
	return func(c *gin.Context) {
		userIDStr := c.Param("id")
		userID, err := uuid.Parse(userIDStr)
		if err != nil {
			handleError(c, http.StatusBadRequest, "ID utilisateur invalide")
			return
		}

		var servers []models.Server

		if err := db.GetDB().Table("servers").
			Joins("LEFT JOIN on_servers ON servers.id = on_servers.server_id AND on_servers.user_id = ? AND on_servers.deleted_at IS NULL", userID).
			Joins("LEFT JOIN bans ON servers.id = bans.server_id AND bans.user_id = ? AND bans.deleted_at IS NULL", userID).
			Where("servers.user_id != ?", userID).
			Where("servers.visibility = ?", "public").
			Where("on_servers.user_id IS NULL").
			Where("bans.user_id IS NULL").
			Preload("Media").
			Preload("Tags").
			Find(&servers).Error; err != nil {
			handleError(c, http.StatusInternalServerError, "Erreur lors de la récupération des serveurs publics disponibles")
			return
		}

		c.JSON(http.StatusOK, gin.H{"data": servers})
	}
}

func LeaveServer() gin.HandlerFunc {
	return func(c *gin.Context) {
		serverIDStr := c.Param("id")
		serverID, err := uuid.Parse(serverIDStr)
		if err != nil {
			handleError(c, http.StatusBadRequest, "ID de serveur invalide")
			return
		}

		claims, exists := c.Get("jwt_claims")
		if !exists {
			handleError(c, http.StatusUnauthorized, "Erreur lors de la récupération des revendications JWT")
			return
		}

		jwtClaims, ok := claims.(jwt.MapClaims)
		if !ok {
			handleError(c, http.StatusInternalServerError, "Erreur lors de l'extraction des revendications JWT")
			return
		}

		userIDStr, ok := jwtClaims["jti"].(string)
		if !ok {
			handleError(c, http.StatusInternalServerError, "Erreur lors de la récupération de l'ID utilisateur")
			return
		}

		userID, err := uuid.Parse(userIDStr)
		if err != nil {
			handleError(c, http.StatusInternalServerError, "Erreur lors de la conversion de l'ID utilisateur")
			return
		}

		tx := db.GetDB().Begin()
		defer func() {
			if r := recover(); r != nil {
				tx.Rollback()
				handleError(c, http.StatusInternalServerError, "Erreur lors de la transaction.")
				return
			}
		}()

		var onServer models.OnServer
		if err := tx.Where("server_id = ? AND user_id = ?", serverID, userID).First(&onServer).Error; err != nil {
			tx.Rollback()
			handleError(c, http.StatusBadRequest, "L'utilisateur n'est pas sur le serveur.")
			return
		}

		if err := tx.Delete(&onServer).Error; err != nil {
			tx.Rollback()
			handleError(c, http.StatusInternalServerError, "Erreur lors de la suppression de l'association serveur-utilisateur.")
			return
		}

		var roleUser models.RoleUser
		if err := tx.Where("role_id IN (SELECT id FROM roles WHERE server_id = ?) AND user_id = ?", serverID, userID).First(&roleUser).Error; err == nil {
			if err := tx.Delete(&roleUser).Error; err != nil {
				tx.Rollback()
				handleError(c, http.StatusInternalServerError, "Erreur lors de la suppression de l'association rôle-utilisateur.")
				return
			}
		}

		tx.Commit()

		c.JSON(http.StatusOK, gin.H{"data": onServer})
	}
}

func GetServersByUser() gin.HandlerFunc {
	return func(c *gin.Context) {
		userIDStr := c.Param("id")
		userID, err := uuid.Parse(userIDStr)
		if err != nil {
			handleError(c, http.StatusBadRequest, "ID utilisateur invalide")
			return
		}

		var servers []models.Server
		if err := db.GetDB().Table("servers").
			Joins("JOIN on_servers ON servers.id = on_servers.server_id").
		if err := db.GetDB().Table("servers").
			Joins("JOIN on_servers ON servers.id = on_servers.server_id AND on_servers.deleted_at IS NULL").
			Joins("LEFT JOIN bans ON servers.id = bans.server_id AND bans.user_id = ?", userID).
			Preload("Media").
			Preload("Tags").
			Where("on_servers.user_id = ? AND on_servers.deleted_at IS NULL", userID).
			Where("on_servers.user_id = ?", userID).
			Where("(bans.user_id IS NULL OR bans.deleted_at IS NOT NULL)").
			Find(&servers).Error; err != nil {
			handleError(c, http.StatusInternalServerError, "Error retrieving user's servers")
			return
		}

		c.JSON(http.StatusOK, gin.H{"data": servers})
	}
}

func GetServerMembers() gin.HandlerFunc {
	return func(c *gin.Context) {
		serverIDStr := c.Param("id")
		serverID, err := uuid.Parse(serverIDStr)
		if err != nil {
			handleError(c, http.StatusBadRequest, "ID de serveur invalide")
			return
		}

		var server models.Server
		if err := db.GetDB().First(&server, serverID).Error; err != nil {
			handleError(c, http.StatusBadRequest, "Le serveur n'existe pas.")
			return
		}

		var users []models.User
		if err := db.GetDB().Table("users").
			Joins("JOIN on_servers ON users.id = on_servers.user_id").
			Where("on_servers.server_id = ?", serverID).
			Where("on_servers.deleted_at IS NULL").
			Find(&users).Error; err != nil {
			handleError(c, http.StatusInternalServerError, "Erreur lors de la récupération des membres du serveur.")
			return
		}

		c.JSON(http.StatusOK, gin.H{"data": users})
	}
}

func GetServerChannels() gin.HandlerFunc {
	return func(c *gin.Context) {
		serverIDStr := c.Param("id")
		serverID, err := uuid.Parse(serverIDStr)
		if err != nil {
			handleError(c, http.StatusBadRequest, "ID de serveur invalide")
			return
		}

		var server models.Server
		if err := db.GetDB().First(&server, serverID).Error; err != nil {
			handleError(c, http.StatusBadRequest, "Le serveur n'existe pas.")
			return
		}

		var textChannels []models.Channel
		if err := db.GetDB().Where("server_id = ? AND type = ?", serverID, "text").Find(&textChannels).Error; err != nil {
			handleError(c, http.StatusInternalServerError, "Erreur lors de la récupération des canaux de texte du serveur.")
			return
		}

		var voiceChannels []models.Channel
		if err := db.GetDB().Where("server_id = ? AND type = ?", serverID, "vocal").Find(&voiceChannels).Error; err != nil {
			handleError(c, http.StatusInternalServerError, "Erreur lors de la récupération des canaux vocaux du serveur.")
			return
		}

		c.JSON(http.StatusOK, gin.H{"text": textChannels, "vocal": voiceChannels})
	}
}

func GetServerLogs() gin.HandlerFunc {
	return func(c *gin.Context) {
		serverIDStr := c.Param("id")
		serverID, err := uuid.Parse(serverIDStr)
		if err != nil {
			handleError(c, http.StatusBadRequest, "ID de serveur invalide")
			return
		}

		var server models.Server
		if err := db.GetDB().First(&server, serverID).Error; err != nil {
			handleError(c, http.StatusBadRequest, "Le serveur n'existe pas.")
			return
		}

		var logs []models.Logs
		if err := db.GetDB().Where("server_id = ?", serverID).Find(&logs).Error; err != nil {
			handleError(c, http.StatusInternalServerError, "Erreur lors de la récupération des logs du serveur.")
			return
		}

		c.JSON(http.StatusOK, gin.H{"data": logs})
	}
}

func UpdateServerByID() gin.HandlerFunc {
	return func(c *gin.Context) {
		serverIDStr := c.Param("id")
		serverID, err := uuid.Parse(serverIDStr)
		if err != nil {
			handleError(c, http.StatusBadRequest, "ID de serveur invalide")
			return
		}

		var input UpdateServerInput
		if err := c.ShouldBindJSON(&input); err != nil {
			handleError(c, http.StatusBadRequest, "Erreur lors de la liaison des données JSON")
			return
		}

		var server models.Server
		if err := db.GetDB().Preload("Tags").First(&server, serverID).Error; err != nil {
			handleError(c, http.StatusNotFound, "Serveur non trouvé")
			return
		}

		if input.Name != "" {
			server.Name = input.Name
		}
		if input.Visibility != "" {
			server.Visibility = input.Visibility
		}
		if input.MediaID != uuid.Nil {
			server.MediaID = input.MediaID
		}

		tx := db.GetDB().Begin()

		if len(input.TagIDs) > 0 {
			var existingTags []models.Tag

			if err := tx.Where("id IN ?", input.TagIDs).Find(&existingTags).Error; err != nil {
				tx.Rollback()
				handleError(c, http.StatusInternalServerError, "Erreur lors de la récupération des tags")
				return
			}

			existingTagIDs := make(map[uuid.UUID]bool)
			for _, tag := range existingTags {
				existingTagIDs[tag.ID] = true
			}

			for _, tagID := range input.TagIDs {
				if !existingTagIDs[tagID] {
					tx.Rollback()
					handleError(c, http.StatusBadRequest, fmt.Sprintf("Le tag avec l'ID %d n'existe pas", tagID))
					return
				}
			}

			if err := tx.Model(&server).Association("Tags").Replace(existingTags); err != nil {
				tx.Rollback()
				handleError(c, http.StatusInternalServerError, "Erreur lors de la mise à jour des tags du serveur")
				return
			}
		}

		if err := tx.Save(&server).Error; err != nil {
			tx.Rollback()
			handleError(c, http.StatusInternalServerError, "Erreur lors de la mise à jour du serveur")
			return
		}

		tx.Commit()

		if err := db.GetDB().Preload("Tags").First(&server, serverID).Error; err != nil {
			handleError(c, http.StatusInternalServerError, "Erreur lors de la récupération des tags après mise à jour")
			return
		}

		c.JSON(http.StatusOK, server)
	}
}

func handleError(c *gin.Context, statusCode int, message string) {
	c.JSON(statusCode, gin.H{"error": message})
}
