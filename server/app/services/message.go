package services

import (
	"app/db"
	"app/db/models"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

func GetMessageReactions() gin.HandlerFunc {
	return func(c *gin.Context) {
		messageIDStr := c.Param("id")

		messageID, err := uuid.Parse(messageIDStr)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid message ID"})
			return
		}

		var reactMessages []models.ReactMessage
		var reactionsCount int64

		if err := db.GetDB().Where("message_id = ?", messageID).Preload("React").Find(&reactMessages).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to retrieve reactions"})
			return
		}

		// Comptage du nombre de réactions
		if err := db.GetDB().Model(&models.ReactMessage{}).Where("message_id = ?", messageID).Count(&reactionsCount).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to count reactions"})
			return
		}

		c.JSON(http.StatusOK, gin.H{"data": reactMessages, "count": reactionsCount})
	}
}
