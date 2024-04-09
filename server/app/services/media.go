package services

import (
	"app/db/models"
	"app/controllers"
	"github.com/gin-gonic/gin"
	"net/http"
	"path/filepath"
	"app/db"
)

func UploadFile(c *gin.Context) {
	c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, controllers.MaxUploadSize+512) 

	file, fileHeader, err := c.Request.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Aucun fichier fourni"})
		return
	}
	defer file.Close()

	if err := controllers.ValidateFileUpload(fileHeader); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	filePath := filepath.Join("upload", fileHeader.Filename)
	if err := c.SaveUploadedFile(fileHeader, filePath); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Échec de l'enregistrement du fichier"})
		return
	}

	media := models.Media{
		FileName: fileHeader.Filename,
		MimeType: fileHeader.Header.Get("Content-Type"),
		URL:      filePath,
	}

	result := db.GetDB().Create(&media)
        if result.Error != nil {
            c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
            return
        }

	c.JSON(http.StatusOK, gin.H{"message": "Fichier uploadé avec succès", "path": filePath})
}
