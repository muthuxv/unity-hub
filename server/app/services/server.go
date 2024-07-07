package services

import (
	"app/db"
	"app/db/models"
	"errors"
	"fmt"
	"log"
	"net/http"
	"strconv"

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

type TagsInput struct {
	TagIDs []uuid.UUID `json:"tag_ids"`
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

		userID, err := strconv.Atoi(userIDStr)
		if err != nil {
			handleError(c, http.StatusInternalServerError, "Erreur lors de la conversion de l'ID utilisateur")
			return
		}

		var servers []models.Server

		// Query servers excluding those where user is already on
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
			// Default media
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

		// Create server
		if err := tx.Create(&inputServer).Error; err != nil {
			tx.Rollback()
			handleError(c, http.StatusInternalServerError, "Erreur lors de la création du serveur")
			return
		}

		// Preload media
		if err := tx.Preload("Media").First(&inputServer).Error; err != nil {
			tx.Rollback()
			handleError(c, http.StatusInternalServerError, "Erreur lors du préchargement du média")
			return
		}

		// Create association server-user
		inputOnServer := models.OnServer{
			ServerID: inputServer.ID,
			UserID:   userID,
		}
		if err := tx.Create(&inputOnServer).Error; err != nil {
			tx.Rollback()
			handleError(c, http.StatusInternalServerError, "Erreur lors de la création de l'association serveur-utilisateur")
			return
		}

		// Create default role
		inputRole := models.Role{
			ServerID: inputServer.ID,
			Label:    "membre",
		}
		if err := tx.Create(&inputRole).Error; err != nil {
			tx.Rollback()
			handleError(c, http.StatusInternalServerError, "Erreur lors de la création du rôle")
			return
		}

		// Create role-user association
		inputRoleUser := models.RoleUser{
			RoleID: inputRole.ID,
			UserID: userID,
		}
		if err := tx.Create(&inputRoleUser).Error; err != nil {
			tx.Rollback()
			handleError(c, http.StatusInternalServerError, "Erreur lors de la création de l'association rôle-utilisateur")
			return
		}

		// Create default channel
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

		// Commit transaction if all operations succeed
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

		// Begin a transaction
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
		log.Println(userIDStr)
		userID, err := uuid.Parse(userIDStr)
		if err != nil {
			handleError(c, http.StatusBadRequest, "ID utilisateur invalide")
			return
		}

		var servers []models.Server
		if err := db.GetDB().Table("servers").Joins("JOIN on_servers ON servers.id = on_servers.server_id").
			Preload("Media").
			Preload("Tags").
			Where("on_servers.user_id = ?", userID).
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
		if err := db.GetDB().Table("users").Joins("JOIN on_servers ON users.id = on_servers.user_id").Where("on_servers.server_id = ?", serverID).Find(&users).Error; err != nil {
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

		// Mise à jour des champs du serveur
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

		// Mise à jour des tags
		if len(input.TagIDs) > 0 {
			var existingTags []models.Tag

			// Vérifier l'existence des tags dans la base de données
			if err := tx.Where("id IN ?", input.TagIDs).Find(&existingTags).Error; err != nil {
				tx.Rollback()
				handleError(c, http.StatusInternalServerError, "Erreur lors de la récupération des tags")
				return
			}

			// Vérifier que tous les tags spécifiés existent
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

			// Mettre à jour les tags du serveur
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

		// Récupération du serveur mis à jour avec ses tags
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
