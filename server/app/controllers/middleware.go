package controllers

import (
	"app/db"
	"app/db/models"
	"github.com/gin-gonic/gin"
	"net/http"
	"github.com/golang-jwt/jwt/v4"
	"strconv"
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
        id, err := strconv.Atoi(serverIDStr)
        if err != nil {
            return 
        }
        serverID := uint(id)

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

        _, err = strconv.Atoi(userIDStr)
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
