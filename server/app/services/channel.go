package services

import (
    "net/http"
    "app/db"
    "app/db/models"
    "github.com/gin-gonic/gin"
)

func GetChannelMessages() gin.HandlerFunc {
    return func(c *gin.Context) {
        var messages []models.Message
        channelID := c.Param("id")

        if err := db.GetDB().Where("channel_id = ?", channelID).Find(&messages).Error; err != nil {
            c.Error(err)
            return
        }

        c.JSON(http.StatusOK, messages)
    }
}
