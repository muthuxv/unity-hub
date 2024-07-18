package services

import (
	"app/db"
	"app/db/models"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

func CreateFeature() gin.HandlerFunc {
	return func(c *gin.Context) {
		var feature models.Feature

		if err := c.ShouldBindJSON(&feature); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Entrée invalide"})
			return
		}

		if feature.Name == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Le nom de la feature ne peut pas être vide"})
			return
		}

		var existingFeature models.Feature
		if err := db.GetDB().Where("name = ?", feature.Name).First(&existingFeature).Error; err == nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Le nom de la feature existe déjà"})
			return
		}

		feature.ID = uuid.New()

		if err := db.GetDB().Create(&feature).Error; err != nil {
			c.Error(err)
			return
		}

		c.JSON(http.StatusCreated, feature)
	}
}

func UpdateFeature() gin.HandlerFunc {
	return func(c *gin.Context) {
		featureID := c.Param("id")

		if _, err := uuid.Parse(featureID); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "ID de feature invalide"})
			return
		}

		var existingFeature models.Feature
		if err := db.GetDB().Where("id = ?", featureID).First(&existingFeature).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Feature non trouvée"})
			return
		}

		var updatedFeature models.Feature
		if err := c.ShouldBindJSON(&updatedFeature); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Entrée invalide"})
			return
		}

		if updatedFeature.Name == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Le nom de la feature ne peut pas être vide"})
			return
		}

		if updatedFeature.Name != existingFeature.Name {
			var checkFeature models.Feature
			if err := db.GetDB().Where("name = ?", updatedFeature.Name).First(&checkFeature).Error; err == nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Le nom de la feature existe déjà"})
				return
			}
		}

		existingFeature.Name = updatedFeature.Name

		if err := db.GetDB().Save(&existingFeature).Error; err != nil {
			c.Error(err)
			return
		}

		c.JSON(http.StatusOK, existingFeature)
	}
}
