package services

import (
	"app/db"
	"app/db/models"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

func CreateTag() gin.HandlerFunc {
	return func(c *gin.Context) {
		var tag models.Tag

		if err := c.ShouldBindJSON(&tag); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		var existingTag models.Tag
		if err := db.GetDB().Where("name = ?", tag.Name).First(&existingTag).Error; err == nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Le nom du tag existe déjà"})
			return
		}

		tag.ID = uuid.New()

		if err := db.GetDB().Create(&tag).Error; err != nil {
			c.Error(err)
			return
		}

		c.JSON(http.StatusCreated, tag)
	}
}

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
		tagID, err := uuid.Parse(c.Param("id"))
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
