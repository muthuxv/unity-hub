package services

import (
	"app/db/models"
	"app/controllers"
	"github.com/gin-gonic/gin"
	"net/http"
	"path/filepath"
	"app/db"
	"fmt"
	"github.com/golang-jwt/jwt/v4"
)

func UploadFile(c *gin.Context) {
    c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, controllers.MaxUploadSize+512) 

    file, fileHeader, err := c.Request.FormFile("file")
    if err != nil {
        c.Error(fmt.Errorf("Aucun fichier fourni"))
        return
    }
    defer file.Close()

    if err := controllers.ValidateFileUpload(fileHeader); err != nil {
        c.Error(err)
        return
    }

    filePath := filepath.Join("upload", fileHeader.Filename)
    if err := c.SaveUploadedFile(fileHeader, filePath); err != nil {
        c.Error(err)
        return
    }

    claims, exists := c.Get("jwt_claims")
    if !exists {
        c.Error(fmt.Errorf("Erreur lors de la récupération des informations d'utilisateur"))
        return
    }

    jwtClaims := claims.(jwt.MapClaims)
    userID, ok := jwtClaims["jti"].(string)
    if !ok {
        c.Error(fmt.Errorf("Erreur lors de la récupération de l'ID utilisateur")) 
        return
    }

    var userIDUint uint
    fmt.Sscanf(userID, "%d", &userIDUint)

    media := models.Media{
        FileName: fileHeader.Filename,
        MimeType: fileHeader.Header.Get("Content-Type"),
        UserID:   userIDUint,
    }

    result := db.GetDB().Create(&media)
    if result.Error != nil {
        c.Error(result.Error) 
        return
    }

    c.JSON(http.StatusOK, gin.H{"message": "Fichier uploadé avec succès", "path": filePath})
}