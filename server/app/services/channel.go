package services

import (
	"app/db"
	"app/db/models"
	"net/http"

	"github.com/gin-gonic/gin"
)

func GetChannelMessages() gin.HandlerFunc {
	return func(c *gin.Context) {
		var messages []models.Message
		channelID := c.Param("id")

		if err := db.GetDB().Where("channel_id = ?", channelID).Order("sent_at").Preload("User").Find(&messages).Error; err != nil {
			c.Error(err)
			return
		}

		var messagesResponse []map[string]interface{}
		for _, message := range messages {
			messagesResponse = append(messagesResponse, map[string]interface{}{
				"ID":      message.ID,
				"Content": message.Content,
				"Type":    message.Type,
				"SentAt":  message.SentAt,
				"UserID":  message.UserID,
				"User": map[string]interface{}{
					"Pseudo":  message.User.Pseudo,
					"Profile": message.User.Profile,
				},
			})
		}

		c.JSON(http.StatusOK, messagesResponse)
	}
}

func GetUserChannels() gin.HandlerFunc {
	return func(c *gin.Context) {
		var channels []models.Channel
		userID := c.Param("id")

		var servers []models.Server
		if err := db.GetDB().Table("servers").Joins("JOIN on_servers ON servers.id = on_servers.server_id").
			Preload("Media").
			Preload("Tags").
			Where("on_servers.user_id = ?", userID).
			Find(&servers).Error; err != nil {
			handleError(c, http.StatusInternalServerError, "Error retrieving user's servers")
			return
		}

		for _, server := range servers {
			var serverChannels []models.Channel
			if err := db.GetDB().Where("server_id = ?", server.ID).Find(&serverChannels).Error; err != nil {
				handleError(c, http.StatusInternalServerError, "Error retrieving server's channels")
				return
			}

			channels = append(channels, serverChannels...)
		}

		c.JSON(http.StatusOK, channels)
	}
}
