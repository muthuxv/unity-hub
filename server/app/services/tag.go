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
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input"})
			return
		}

		if tag.Name == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Le nom du tag ne peut pas être vide"})
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

func UpdateTag() gin.HandlerFunc {
	return func(c *gin.Context) {
		tagID := c.Param("id")

		if _, err := uuid.Parse(tagID); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "ID de tag invalide"})
			return
		}

		var existingTag models.Tag
		if err := db.GetDB().Where("id = ?", tagID).First(&existingTag).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Tag non trouvé"})
			return
		}

		var updatedTag models.Tag
		if err := c.ShouldBindJSON(&updatedTag); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Entrée invalide"})
			return
		}

		if updatedTag.Name == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Le nom du tag ne peut pas être vide"})
			return
		}

		if updatedTag.Name != existingTag.Name {
			var checkTag models.Tag
			if err := db.GetDB().Where("name = ?", updatedTag.Name).First(&checkTag).Error; err == nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Le nom du tag existe déjà"})
				return
			}
		}

		existingTag.Name = updatedTag.Name

		if err := db.GetDB().Save(&existingTag).Error; err != nil {
			c.Error(err)
			return
		}

		c.JSON(http.StatusOK, existingTag)
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
