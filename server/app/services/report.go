package services

import (
	"app/db"
	"app/db/models"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"log"
	"net/http"
)

func getReportsByServerAndStatus(c *gin.Context, status string) {
	serverIDStr := c.Param("id")
	log.Println("ServerID:", serverIDStr)
	log.Println("Status:", status)

	serverID, err := uuid.Parse(serverIDStr)
	if err != nil {
		handleError(c, http.StatusBadRequest, "Invalid server ID")
		return
	}

	if status == "" {
		handleError(c, http.StatusBadRequest, "Status is required")
		return
	}

	var reports []models.Report
	result := db.GetDB().
		Preload("ReportedMessage").
		Preload("ReportedMessage.User").
		Preload("Reporter").
		Where("server_id = ? AND status = ?", serverID, status).
		Find(&reports)
	if result.Error != nil {
		handleError(c, http.StatusInternalServerError, "Error retrieving reports")
		return
	}

	c.JSON(http.StatusOK, gin.H{"data": reports})
}

func GetPendingReportsByServer() gin.HandlerFunc {
	return func(c *gin.Context) {
		getReportsByServerAndStatus(c, "pending")
	}
}

func GetFinishedReportsByServer() gin.HandlerFunc {
	return func(c *gin.Context) {
		getReportsByServerAndStatus(c, "finished")
	}
}
