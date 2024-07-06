package controllers

import (
	"app/db"
	"app/db/models"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v4"
	"github.com/google/uuid"
)

func ErrorHandling() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Next()

		if len(c.Errors) > 0 {
			err := c.Errors.Last().Err
			switch err.(type) {
			case *gin.Error:
				c.JSON(http.StatusInternalServerError, gin.H{"Muthu error": err.Error()})
			default:
				c.JSON(http.StatusInternalServerError, gin.H{"Muthu error": "Une erreur inconnue est survenue"})
			}
			c.Abort()
		}
	}
}

func GenerateLogMiddleware(action string) gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Next()

		serverIDStr := c.Param("id")
		_, err := uuid.Parse(serverIDStr)
		if err != nil {
			return
		}

		serverID := uuid.MustParse(serverIDStr)

		claims, exists := c.Get("jwt_claims")
		if !exists {
			return
		}

		jwtClaims, ok := claims.(jwt.MapClaims)
		if !ok {
			return
		}

		userIDStr, ok := jwtClaims["jti"].(string)
		if !ok {
			return
		}

		_, err = uuid.Parse(userIDStr)
		if err != nil {
			return
		}

		logEntry := models.Logs{
			Message:  "User " + userIDStr + " " + action + " server",
			ServerID: serverID,
		}

		db.GetDB().Create(&logEntry)
	}
}
