package services

import (
	"app/db"
	"app/db/models"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

func GetMessageReactions() gin.HandlerFunc {
	return func(c *gin.Context) {
		messageIDStr := c.Param("id")

		// Vérifier si l'ID du message est un UUID valide
		messageID, err := uuid.Parse(messageIDStr)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "ID de message invalide"})
			return
		}

		// Vérifier si le message avec cet ID existe en base de données
		var message models.Message
		if err := db.GetDB().Where("id = ?", messageID).First(&message).Error; err != nil {
			if err == gorm.ErrRecordNotFound {
				c.JSON(http.StatusNotFound, gin.H{"error": "Message non trouvé"})
				return
			}
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Erreur lors de la récupération du message"})
			return
		}

		var reactMessages []models.ReactMessage
		var reactionsCount int64

		// Récupérer les réactions pour le message spécifié
		if err := db.GetDB().Where("message_id = ?", messageID).Preload("React").Find(&reactMessages).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Échec de la récupération des réactions"})
			return
		}

		// Comptage du nombre de réactions
		if err := db.GetDB().Model(&models.ReactMessage{}).Where("message_id = ?", messageID).Count(&reactionsCount).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Échec du comptage des réactions"})
			return
		}

		c.JSON(http.StatusOK, gin.H{"data": reactMessages, "count": reactionsCount})
	}
}
