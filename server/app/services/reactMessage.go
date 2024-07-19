package services

import (
	"app/db"
	"app/db/models"
	"errors"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v4"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

func CreateReactMessage() gin.HandlerFunc {
	return func(c *gin.Context) {
		var input struct {
			ReactID   uuid.UUID `json:"reactId" binding:"required"`
			MessageID uuid.UUID `json:"messageId" binding:"required"`
		}

		if err := c.ShouldBindJSON(&input); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
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

		var reactType models.React
		if err := db.GetDB().Where("id = ?", input.ReactID).First(&reactType).Error; err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				c.JSON(http.StatusNotFound, gin.H{"error": "Réaction non trouvé"})
				return
			}
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Erreur lors de la récupération de ReactID"})
			return
		}

		var message models.Message
		if err := db.GetDB().Where("id = ?", input.MessageID).First(&message).Error; err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				c.JSON(http.StatusNotFound, gin.H{"error": "Message non trouvé"})
				return
			}
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Erreur lors de la récupération de MessageID"})
			return
		}

		var existingReact models.ReactMessage
		err = db.GetDB().Where("user_id = ? AND react_id = ? AND message_id = ?", userID, input.ReactID, input.MessageID).First(&existingReact).Error
		if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Échec de la vérification des réactions existantes"})
			return
		}

		if existingReact.ID != uuid.Nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "L'utilisateur a déjà réagi avec ce ReactID à ce MessageID"})
			return
		}

		reactMessage := models.ReactMessage{
			UserID:    userID,
			ReactID:   input.ReactID,
			MessageID: input.MessageID,
		}

		if err := db.GetDB().Create(&reactMessage).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Échec de la création de la réaction"})
			return
		}

		c.JSON(http.StatusCreated, gin.H{"data": reactMessage})
	}
}

func DeleteReactMessage() gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")

		// Vérifier si l'UUID est valide
		uid, err := uuid.Parse(id)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid UUID format"})
			return
		}

		// Récupérer les informations JWT
		claims, exists := c.Get("jwt_claims")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
			return
		}

		jwtClaims, ok := claims.(jwt.MapClaims)
		if !ok {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to parse JWT claims"})
			return
		}

		userIDStr, ok := jwtClaims["jti"].(string)
		if !ok {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to retrieve user ID from JWT"})
			return
		}

		userID, err := uuid.Parse(userIDStr)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to parse user ID from JWT"})
			return
		}

		// Vérifier si le ReactMessage existe
		var reactMessage models.ReactMessage
		if err := db.GetDB().Where("id = ?", uid).First(&reactMessage).Error; err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				c.JSON(http.StatusNotFound, gin.H{"error": "ReactMessage not found"})
				return
			}
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to retrieve ReactMessage"})
			return
		}

		// Vérifier si l'utilisateur est autorisé à supprimer le ReactMessage
		if reactMessage.UserID != userID {
			c.JSON(http.StatusForbidden, gin.H{"error": "You are not authorized to delete this ReactMessage"})
			return
		}

		// Supprimer le ReactMessage
		if err := db.GetDB().Delete(&reactMessage).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete ReactMessage"})
			return
		}

		c.Status(http.StatusNoContent)
	}
}
