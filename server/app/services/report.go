package services

import (
	"app/db"
	"app/db/models"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"log"
	"net/http"
)

func GetReportsByServer() gin.HandlerFunc {
	return func(c *gin.Context) {
		serverIDStr := c.Param("serverId")
		status := c.DefaultQuery("status", "pending")
		log.Println(serverIDStr)
		log.Println(status)

		serverID, err := uuid.Parse(serverIDStr)
		if err != nil {
			handleError(c, http.StatusBadRequest, "Invalid server ID")
			return
		}

		var reports []models.Report
		result := db.GetDB().Where("server_id = ? AND status = ?", serverID, status).Find(&reports)
		if result.Error != nil {
			handleError(c, http.StatusInternalServerError, "Error retrieving reports")
			return
		}

		c.JSON(http.StatusOK, gin.H{"data": reports})
	}
}
