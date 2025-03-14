package services

import (
	"app/controllers"
	"app/db"
	"app/db/models"
	"fmt"
	"net/http"
	"path/filepath"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v4"
	"github.com/google/uuid"
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

	userIDUUID, err := uuid.Parse(userID)
	if err != nil {
		c.Error(fmt.Errorf("Erreur lors de la conversion de l'ID utilisateur"))
		return
	}

	media := models.Media{
		FileName: fileHeader.Filename,
		MimeType: fileHeader.Header.Get("Content-Type"),
		UserID:   userIDUUID,
	}

	result := db.GetDB().Create(&media)
	if result.Error != nil {
		c.Error(result.Error)
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Fichier uploadé avec succès", "path": filePath, "id": media.ID})
}
