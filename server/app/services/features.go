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

		// Vérification si l'ID de la feature est valide
		if _, err := uuid.Parse(featureID); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "ID de feature invalide"})
			return
		}

		// Récupération de la feature existante
		var existingFeature models.Feature
		if err := db.GetDB().Where("id = ?", featureID).First(&existingFeature).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Feature non trouvée"})
			return
		}

		// Liaison des données JSON avec la structure de feature mise à jour
		var updatedFeature struct {
			Name   string `json:"name"`
			Status string `json:"status"`
		}
		if err := c.ShouldBindJSON(&updatedFeature); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Entrée invalide"})
			return
		}

		// Vérification du nom de la feature
		if updatedFeature.Name == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Le nom de la feature ne peut pas être vide"})
			return
		}

		// Vérification de l'unicité du nom de la feature si le nom a changé
		if updatedFeature.Name != existingFeature.Name {
			var checkFeature models.Feature
			if err := db.GetDB().Where("name = ?", updatedFeature.Name).First(&checkFeature).Error; err == nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Le nom de la feature existe déjà"})
				return
			}
		}

		// Mise à jour des champs Name et Status de la feature existante
		existingFeature.Name = updatedFeature.Name
		existingFeature.Status = updatedFeature.Status

		// Sauvegarde des modifications dans la base de données
		if err := db.GetDB().Save(&existingFeature).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Échec de la mise à jour de la feature"})
			return
		}

		c.JSON(http.StatusOK, existingFeature)
	}
}
