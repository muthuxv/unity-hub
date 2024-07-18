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

// GetAllServers godoc
// @Summary Get all servers
// @Description Get all servers
// @Tags servers
// @Produce json
// @Success 200 {array} models.ServerSwagger
// @Failure 400 {object} models.ErrorServerResponse
// @Router /servers [get]
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

// GetServerBans godoc
// @Summary Get server bans
// @Description Get all bans for a specific server
// @Tags servers
// @Produce json
// @Param id path string true "Server ID"
// @Success 200 {array} models.BanSwagger
// @Failure 400 {object} models.ErrorServerResponse
// @Router /servers/{id}/bans [get]
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

// GetServersFriendNotIn godoc
// @Summary Get servers friend is not in
// @Description Get servers that a specific friend is not a member of
// @Tags servers
// @Produce json
// @Param friendID path string true "Friend ID"
// @Success 200 {object} models.ServerSwagger
// @Failure 400 {object} models.ErrorServerResponse
// @Router /servers/friend/{friendID} [get]
func GetServersFriendNotIn() gin.HandlerFunc {
	return func(c *gin.Context) {
		claims, exists := c.Get("jwt_claims")
		if !exists {
			handleError(c, http.StatusUnauthorized, "JWT claims not found")
			return
		}

		jwtClaims, ok := claims.(jwt.MapClaims)
		if !ok {
			handleError(c, http.StatusInternalServerError, "Failed to parse JWT claims")
			return
		}

		currentUserIDStr, ok := jwtClaims["jti"].(string)
		if !ok {
			handleError(c, http.StatusInternalServerError, "Failed to get current user ID")
			return
		}

		currentUserID, err := uuid.Parse(currentUserIDStr)
		if err != nil {
			handleError(c, http.StatusInternalServerError, "Failed to parse current user ID")
			return
		}

		friendIDStr := c.Param("friendID")
		friendID, err := uuid.Parse(friendIDStr)
		if err != nil {
			handleError(c, http.StatusBadRequest, "Invalid friend ID")
			return
		}

		var currentUserServers []models.Server
		if err := db.GetDB().
			Table("servers").
			Joins("INNER JOIN on_servers ON servers.id = on_servers.server_id AND on_servers.user_id = ? AND on_servers.deleted_at IS NULL", currentUserID).
			Where("servers.deleted_at IS NULL").
			Find(&currentUserServers).Error; err != nil {
			handleError(c, http.StatusInternalServerError, "Failed to fetch current user's servers")
			return
		}

		var friendServers []models.Server
		if err := db.GetDB().
			Table("servers").
			Joins("INNER JOIN on_servers ON servers.id = on_servers.server_id AND on_servers.user_id = ? AND on_servers.deleted_at IS NULL", friendID).
			Where("servers.deleted_at IS NULL").
			Find(&friendServers).Error; err != nil {
			handleError(c, http.StatusInternalServerError, "Failed to fetch friend's servers")
			return
		}

		var friendBans []models.Ban
		if err := db.GetDB().
			Where("user_id = ? AND deleted_at IS NULL", friendID).
			Find(&friendBans).Error; err != nil {
			handleError(c, http.StatusInternalServerError, "Failed to fetch friend's bans")
			return
		}

		bannedServers := make(map[uuid.UUID]struct{})
		for _, ban := range friendBans {
			bannedServers[ban.ServerID] = struct{}{}
		}

		friendServerMap := make(map[uuid.UUID]struct{})
		for _, server := range friendServers {
			friendServerMap[server.ID] = struct{}{}
		}

		var resultServers []models.Server
		for _, server := range currentUserServers {
			if _, exists := friendServerMap[server.ID]; !exists {
				if _, banned := bannedServers[server.ID]; !banned {
					resultServers = append(resultServers, server)
				}
			}
		}

		c.JSON(http.StatusOK, gin.H{"data": resultServers})
	}
}

// UnbanUser godoc
// @Summary Unban a user from a server
// @Description Unban a user from a specific server
// @Tags servers
// @Accept json
// @Produce json
// @Param id path string true "Server ID"
// @Param userID path string true "User ID"
// @Success 200 {object} models.SuccessServerResponse
// @Failure 400 {object} models.ErrorServerResponse
// @Failure 404 {object} models.ErrorServerResponse
// @Router /servers/{id}/unban/{userID} [delete]
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

// GetServerByID godoc
// @Summary Get a server by ID
// @Description Get details of a specific server by ID
// @Tags servers
// @Produce json
// @Param id path string true "Server ID"
// @Success 200 {object} models.ServerSwagger
// @Failure 400 {object} models.ErrorServerResponse
// @Failure 404 {object} models.ErrorServerResponse
// @Router /servers/{id} [get]
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

// SearchServerByName godoc
// @Summary Search servers by name
// @Description Search for servers by name
// @Tags servers
// @Produce json
// @Param name query string true "Server name"
// @Success 200 {array} models.ServerSwagger
// @Failure 400 {object} models.ErrorServerResponse
// @Router /servers/search [get]
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

// NewServer godoc
// @Summary Create a new server
// @Description Create a new server with specified details
// @Tags servers
// @Accept json
// @Produce json
// @Param server body models.ServerSwagger true "Server details"
// @Success 201 {object} models.ServerSwagger
// @Failure 400 {object} models.ErrorServerResponse
// @Failure 401 {object} models.ErrorServerResponse
// @Failure 500 {object} models.ErrorServerResponse
// @Router /servers [post]
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
			if err := db.GetDB().First(&media).Error; err != nil {
				handleError(c, http.StatusBadRequest, "Le média est requis")
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

		adminRole := models.Role{
			ServerID: inputServer.ID,
			Label:    "admin",
		}
		if err := tx.Create(&adminRole).Error; err != nil {
			tx.Rollback()
			handleError(c, http.StatusInternalServerError, "Erreur lors de la création du rôle admin")
			return
		}

		// Attribution du rôle "admin" à l'utilisateur créateur
		adminRoleUser := models.RoleUser{
			RoleID: adminRole.ID,
			UserID: userID,
		}
		if err := tx.Create(&adminRoleUser).Error; err != nil {
			tx.Rollback()
			handleError(c, http.StatusInternalServerError, "Erreur lors de l'attribution du rôle admin à l'utilisateur")
			return
		}

		// Création du rôle "membre"
		memberRole := models.Role{
			ServerID: inputServer.ID,
			Label:    "membre",
		}
		if err := tx.Create(&memberRole).Error; err != nil {
			tx.Rollback()
			handleError(c, http.StatusInternalServerError, "Erreur lors de la création du rôle membre")
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

// KickUser godoc
// @Summary Kick a user from a server
// @Description Kick a user from a specific server
// @Tags servers
// @Accept json
// @Produce json
// @Param id path string true "Server ID"
// @Param userID path string true "User ID"
// @Success 200 {object} models.SuccessServerResponse
// @Failure 400 {object} models.ErrorServerResponse
// @Failure 404 {object} models.ErrorServerResponse
// @Router /servers/{id}/kick/{userID} [delete]
func KickUser() gin.HandlerFunc {
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

		var onServer models.OnServer
		if err := db.GetDB().Where("server_id = ? AND user_id = ?", serverUUID, userUUID).First(&onServer).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "User is not a member of this server"})
			return
		}

		tx := db.GetDB().Begin()

		if err := tx.Where("server_id = ? AND user_id = ?", serverUUID, userUUID).Delete(&models.OnServer{}).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		if err := tx.Commit().Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "User kicked from server"})
	}
}

// JoinServer godoc
// @Summary Join a server
// @Description Join a specific server by ID
// @Tags servers
// @Accept json
// @Produce json
// @Param id path string true "Server ID"
// @Success 200 {object} models.OnServerSwagger
// @Failure 400 {object} models.ErrorServerResponse
// @Failure 404 {object} models.ErrorServerResponse
// @Router /servers/join/{id} [post]
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

// GetPublicAvailableServers godoc
// @Summary Get public available servers
// @Description Get all public servers that a user is not a member of
// @Tags servers
// @Produce json
// @Param id path string true "User ID"
// @Success 200 {array} models.ServerSwagger
// @Failure 400 {object} models.ErrorServerResponse
// @Router /servers/public/{id} [get]
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

// LeaveServer godoc
// @Summary Leave a server
// @Description Leave a specific server by ID
// @Tags servers
// @Accept json
// @Produce json
// @Param id path string true "Server ID"
// @Success 200 {object} models.OnServerSwagger
// @Failure 400 {object} models.ErrorServerResponse
// @Failure 404 {object} models.ErrorServerResponse
// @Router /servers/leave/{id} [delete]
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

// GetServersByUser godoc
// @Summary Get servers by user ID
// @Description Get all servers that a specific user is a member of
// @Tags servers
// @Produce json
// @Param id path string true "User ID"
// @Success 200 {array} models.ServerSwagger
// @Failure 400 {object} models.ErrorServerResponse
// @Router /servers/user/{id} [get]
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
			Joins("JOIN on_servers ON servers.id = on_servers.server_id AND on_servers.deleted_at IS NULL").
			Joins("LEFT JOIN bans ON servers.id = bans.server_id AND bans.user_id = ?", userID).
			Preload("Media").
			Preload("Tags").
			Where("on_servers.user_id = ? AND (bans.user_id IS NULL OR bans.deleted_at IS NOT NULL)", userID).
			Find(&servers).Error; err != nil {
			handleError(c, http.StatusInternalServerError, "Error retrieving user's servers")
			return
		}

		c.JSON(http.StatusOK, gin.H{"data": servers})
	}
}

// GetServerMembers godoc
// @Summary Get server members
// @Description Get all members of a specific server
// @Tags servers
// @Produce json
// @Param id path string true "Server ID"
// @Success 200 {array} models.User
// @Failure 400 {object} models.ErrorServerResponse
// @Router /servers/{id}/members [get]
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

// GetServerChannels godoc
// @Summary Get server channels
// @Description Get all channels of a specific server
// @Tags servers
// @Produce json
// @Param id path string true "Server ID"
// @Success 200 {object} map[string][]models.ChannelSwagger
// @Failure 400 {object} models.ErrorServerResponse
// @Router /servers/{id}/channels [get]
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

// GetServerLogs godoc
// @Summary Get server logs
// @Description Get all logs of a specific server
// @Tags servers
// @Produce json
// @Param id path string true "Server ID"
// @Success 200 {array} models.LogsSwagger
// @Failure 400 {object} models.ErrorServerResponse
// @Router /servers/{id}/logs [get]
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

// DeleteServerByID godoc
// @Summary Delete server by ID
// @Description Delete a specific server by ID
// @Tags servers
// @Produce json
// @Param id path string true "Server ID"
// @Success 200 {object} models.SuccessServerResponse
// @Failure 400 {object} models.ErrorServerResponse
// @Failure 404 {object} models.ErrorServerResponse
// @Router /servers/{id} [delete]
func DeleteServerByID() gin.HandlerFunc {
	return func(c *gin.Context) {
		serverIDStr := c.Param("id")
		serverID, err := uuid.Parse(serverIDStr)
		if err != nil {
			handleError(c, http.StatusBadRequest, "ID de serveur invalide")
			return
		}

		claims, exists := c.Get("jwt_claims")
		if !exists {
			handleError(c, http.StatusUnauthorized, "Non autorisé")
			return
		}

		jwtClaims := claims.(jwt.MapClaims)
		userIDStr, ok := jwtClaims["jti"].(string)
		if !ok {
			handleError(c, http.StatusInternalServerError, "Échec de l'extraction de l'identifiant utilisateur depuis le JWT")
			return
		}

		userID, err := uuid.Parse(userIDStr)
		if err != nil {
			handleError(c, http.StatusInternalServerError, "Échec de l'extraction de l'identifiant utilisateur depuis le JWT")
			return
		}

		var server models.Server
		if err := db.GetDB().First(&server, serverID).Error; err != nil {
			handleError(c, http.StatusNotFound, "Serveur introuvable")
			return
		}

		if server.UserID != userID {
			handleError(c, http.StatusForbidden, "Seul le créateur du serveur peut le supprimer")
			return
		}

		var serverMembers []models.OnServer
		if err := db.GetDB().Where("server_id = ?", serverID).Find(&serverMembers).Error; err != nil {
			handleError(c, http.StatusInternalServerError, "Échec de la récupération des membres du serveur")
			return
		}

		for _, member := range serverMembers {
			if err := db.GetDB().Delete(&member).Error; err != nil {
				handleError(c, http.StatusInternalServerError, "Échec de la suppression des membres du serveur")
				return
			}
		}

		if err := db.GetDB().Delete(&server).Error; err != nil {
			handleError(c, http.StatusInternalServerError, "Échec de la suppression du serveur")
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "Serveur supprimé avec succès"})
	}
}

func handleError(c *gin.Context, statusCode int, message string) {
	c.JSON(statusCode, gin.H{"error": message})
}
