package services

import (
	"app/controllers"
	"app/db"
	"app/db/models"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"

	"gorm.io/gorm"

	"github.com/gin-gonic/gin"
)

func OAuthCallbackHandler(provider string) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Récupération des données du corps de la requête
		var data map[string]interface{}
		body, err := io.ReadAll(c.Request.Body)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Échec de la lecture du corps de la requête"})
			return
		}
		if err := json.Unmarshal(body, &data); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Échec de l'analyse du corps de la requête"})
			return
		}

		// Logs pour débogage
		fmt.Println(data)

		// Vérification des clés et des types
		email, okEmail := data["email"].(string)
		displayName, okDisplayName := data["displayName"].(string)
		avatar, okAvatar := data["photoURL"].(string)
		if !okEmail || !okDisplayName || !okAvatar {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Données d'entrée invalides"})
			return
		}

		println(email, displayName, avatar)

		var user models.User
		result := db.GetDB().Where("email = ?", email).First(&user)
		if result.Error != nil && !errors.Is(result.Error, gorm.ErrRecordNotFound) {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Erreur de base de données"})
			return
		}

		if result.RowsAffected == 0 {
			user = models.User{
				Email:      email,
				Pseudo:     displayName,
				Provider:   provider,
				IsVerified: true,
				Profile:    avatar,
			}

			if err := db.GetDB().Create(&user).Error; err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Échec de la création de l'utilisateur"})
				return
			}
		} else {
			if user.Provider != provider {
				c.JSON(http.StatusForbidden, gin.H{"error": "Utilisateur déjà existant avec un autre fournisseur"})
				return
			}
		}

		// Génération du JWT
		tokenString, err := controllers.GenerateJWT(user.ID, user.Email, user.Role)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Échec de la génération du JWT"})
			return
		}

		c.JSON(http.StatusOK, gin.H{"token": tokenString})
	}
}
