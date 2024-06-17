package services

import (
	"app/db"
	"app/db/models"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

func GetAllTags() gin.HandlerFunc {
	return func(c *gin.Context) {
		var tags []models.Tag
		if err := db.GetDB().Find(&tags).Error; err != nil {
			c.Error(err)
			return
		}

		c.JSON(http.StatusOK, tags)
	}
}

func GetServersByTag() gin.HandlerFunc {
	return func(c *gin.Context) {
		tagID, err := strconv.Atoi(c.Param("id"))
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid tag ID"})
			return
		}

		var servers []models.Server
		err = db.GetDB().Model(&models.Server{}).
			Preload("Tags").
			Joins("JOIN server_tags ON servers.id = server_tags.server_id").
			Where("server_tags.tag_id = ?", tagID).
			Find(&servers).Error
		if err != nil {
			c.Error(err)
			return
		}

		c.JSON(http.StatusOK, servers)
	}
}
