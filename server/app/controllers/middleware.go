package controllers

import (
	"github.com/gin-gonic/gin"
	"net/http"
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