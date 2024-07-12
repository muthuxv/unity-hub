package services

import (
	"app/db"
	"app/db/models"
	"app/helpers"
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

func SendInvitation(createLink bool) gin.HandlerFunc {
	return func(c *gin.Context) {
		var roleUser models.RoleUser
		userID, err := helpers.GetLoggedInUserID(c)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Erreur lors de la conversion de l'ID utilisateur"})
			return
		}

		// Fetch the role of the logged-in user
		result := db.GetDB().Preload("User").Preload("Role").Where("user_id = ?", userID).First(&roleUser)
		if result.Error != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Erreur lors de la récupération du rôle de l'utilisateur"})
			return
		}

		// Check if the user is an admin
		if roleUser.Role.Label != "admin" {
			c.JSON(http.StatusForbidden, gin.H{"error": "Vous devez être administrateur pour créer une invitation",
				"role": roleUser,
			})
			return
		}

		// Get the ServerID from the URL parameter
		serverIDStr := c.Param("id")
		serverID, err := uuid.Parse(serverIDStr)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "ID du serveur invalide"})
			return
		}

		// Get the UserReceiverID from the request body
		var receiver struct {
			UserReceiverID string `json:"userReceiverId"`
		}
		if err := c.ShouldBindJSON(&receiver); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "ID du destinataire invalide"})
			return
		}

		userReceiverID, err := uuid.Parse(receiver.UserReceiverID)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "ID du destinataire invalide"})
			return
		}

		// Check if the UserReceiver is already a member of the server
		var membershipCount int64
		result = db.GetDB().Table("on_servers").Where("user_id = ? AND server_id = ? AND deleted_at IS NULL", userReceiverID, serverID).Count(&membershipCount)
		if result.Error != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Erreur lors de la vérification de l'appartenance au serveur"})
			return
		}

		if membershipCount > 0 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "L'utilisateur fait déjà partie du serveur"})
			return
		}

		// Check if the UserReceiver has already received an invitation for this server
		var count int64
		result = db.GetDB().Table("invitations").
			Where("user_receiver_id = ? AND server_id = ? AND deleted_at IS NULL AND expire > ?", userReceiverID, serverID, time.Now()).
			Count(&count)
		if result.Error != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Erreur lors de la vérification des invitations existantes"})
			return
		}

		if count > 0 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "L'utilisateur a déjà reçu une invitation valide pour ce serveur"})
			return
		}

		invitation := models.Invitation{
			UserSenderID:   userID,
			UserReceiverID: userReceiverID,
			ServerID:       serverID,
			Expire:         time.Now().Add(72 * time.Hour),
		}

		if createLink {
			invitation.Expire = time.Now().Add(1 * time.Hour)
			invitation.Link = fmt.Sprintf("http://localhost:8080/servers/%s/join", serverID)
		}

		result = db.GetDB().Create(&invitation)
		if result.Error != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Erreur lors de la création de l'invitation",
				"receiver": receiver.UserReceiverID})
			return
		}

		c.JSON(http.StatusCreated, invitation)
	}
}

func GetInvitationsByUser() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get the user's ID from the URL parameter
		userIDStr := c.Param("id")
		userID, err := uuid.Parse(userIDStr)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "ID utilisateur invalide"})
			return
		}

		// Fetch all invitations where the user is the receiver
		var invitations []models.Invitation
		result := db.GetDB().Preload("Server").Preload("UserSender").Where("user_receiver_id = ?", userID).Find(&invitations)
		if result.Error != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Erreur lors de la récupération des invitations"})
			return
		}

		// Return the invitations
		c.JSON(http.StatusOK, invitations)
	}
}
