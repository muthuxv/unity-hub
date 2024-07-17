package services

import (
	"app/db"
	"app/db/models"
	"log"
	"net/http"
	"github.com/google/uuid"

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

		c.JSON(http.StatusOK, messages)
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

		log.Printf("User %s has %d channels\n", userID, len(channels))

		c.JSON(http.StatusOK, channels)
	}
}

type ChannelPermissionResponse struct {
	Label string `json:"label"`
	Power int    `json:"power"`
}

func GetChannelPermissions(c *gin.Context) {
	channelID := c.Param("id")
	channelUUID, err := uuid.Parse(channelID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid channel ID"})
		return
	}

	var permissions []ChannelPermissionResponse
	if err := db.GetDB().Table("channel_channel_permissions").
		Select("channel_permissions.label, channel_channel_permissions.power").
		Joins("inner join channel_permissions on channel_permissions.id = channel_channel_permissions.channel_permission_id").
		Where("channel_channel_permissions.channel_id = ?", channelUUID).
		Scan(&permissions).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error fetching channel permissions"})
		return
	}

	c.JSON(http.StatusOK, permissions)
}

func UpdateChannelPermissions(c *gin.Context) {
	channelID := c.Param("id")
	channelUUID, err := uuid.Parse(channelID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid channel ID"})
		return
	}

	availablePermissions := map[string]struct{}{
		"sendMessage":   {},
		"accessChannel": {},
		"editChannel":   {},
	}

	var requestBody map[string]int
	if err := c.BindJSON(&requestBody); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	for key := range availablePermissions {
		power, exists := requestBody[key]
		if !exists || power < 0 || power > 99 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Missing parameters or invalid power value"})
			return
		}
	}

	tx := db.GetDB().Begin()

	var updatedPermissions []ChannelPermissionResponse

	for label, power := range requestBody {
		var permission models.ChannelPermissions
		if err := tx.Where("label = ?", label).First(&permission).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Error fetching permission"})
			return
		}

		var channelPermission models.ChannelChannelPermissions
		if err := tx.Where("channel_id = ? AND channel_permission_id = ?", channelUUID, permission.ID).First(&channelPermission).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Error fetching channel permission"})
			return
		}

		channelPermission.Power = power
		if err := tx.Save(&channelPermission).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Error updating channel permission"})
			return
		}

		updatedPermissions = append(updatedPermissions, ChannelPermissionResponse{
			Label: label,
			Power: power,
		})
	}

	tx.Commit()
	c.JSON(http.StatusOK, updatedPermissions)
}
