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

		var existingReact models.ReactMessage
		err = db.GetDB().Where("user_id = ? AND react_id = ? AND message_id = ?", userID, input.ReactID, input.MessageID).First(&existingReact).Error
		if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to query existing reactions"})
			return
		}

		if existingReact.ID != uuid.Nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "user already reacted with this reactId to this messageId"})
			return
		}

		reactMessage := models.ReactMessage{
			UserID:    userID,
			ReactID:   input.ReactID,
			MessageID: input.MessageID,
		}

		if err := db.GetDB().Create(&reactMessage).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create react message"})
			return
		}

		c.JSON(http.StatusCreated, gin.H{"data": reactMessage})
	}
}
