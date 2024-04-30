package helpers

import (
	"errors"
	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v4"
	"strconv"
)

func GetLoggedInUserID(c *gin.Context) (int, error) {
	claims, exists := c.Get("jwt_claims")
	if !exists {
		return 0, gin.Error{
			Err:  errors.New("Erreur lors de la récupération des revendications JWT"),
			Type: gin.ErrorTypePublic,
			Meta: gin.H{"error": "Erreur lors de la récupération des revendications JWT"},
		}
	}

	jwtClaims, ok := claims.(jwt.MapClaims)
	if !ok {
		return 0, gin.Error{
			Err:  errors.New("Erreur lors de l'extraction des revendications JWT"),
			Type: gin.ErrorTypePublic,
			Meta: gin.H{"error": "Erreur lors de l'extraction des revendications JWT"},
		}
	}

	userIDStr, ok := jwtClaims["jti"].(string)
	if !ok {
		return 0, gin.Error{
			Err:  errors.New("Erreur lors de la récupération de l'ID utilisateur"),
			Type: gin.ErrorTypePublic,
			Meta: gin.H{"error": "Erreur lors de la récupération de l'ID utilisateur"},
		}
	}

	userID, err := strconv.Atoi(userIDStr)
	if err != nil {
		return 0, gin.Error{
			Err:  errors.New("Erreur lors de la conversion de l'ID utilisateur"),
			Type: gin.ErrorTypePublic,
			Meta: gin.H{"error": "Erreur lors de la conversion de l'ID utilisateur"},
		}
	}

	return userID, nil
}
