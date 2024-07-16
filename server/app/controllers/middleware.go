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

		userPseudo, ok := jwtClaims["pseudo"].(string)
		if !ok {
			return
		}

		logEntry := models.Logs{
			Message:  "User " + userPseudo + " " + action + " server",
			ServerID: serverID,
		}

		db.GetDB().Create(&logEntry)
	}
}

func GenerateLogBanMiddlaware() gin.HandlerFunc {
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

		userPseudo, ok := jwtClaims["pseudo"].(string)
		if !ok {
			return
		}

		userID := c.Param("userID")
		if userID == "" {
			return
		}

		_, err = uuid.Parse(userID)
		if err != nil {
			return
		}

		var user models.User
		db.GetDB().Where("id = ?", userID).First(&user)

		logEntry := models.Logs{
			Message:  "User " + userPseudo + " banned " + user.Pseudo + " from server",
			ServerID: serverID,
		}

		db.GetDB().Create(&logEntry)
	}
}

func GenerateLogChannelMiddlaware(action string) gin.HandlerFunc {
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
			Message:  "User " + userIDStr + " " + action + " a channel",
			ServerID: serverID,
		}

		db.GetDB().Create(&logEntry)
	}
}
