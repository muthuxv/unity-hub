package services

import (
	"app/db"
	"app/db/models"
	"github.com/gin-gonic/gin"
	"net/http"
	"strconv"
)

type ModelFactory func() interface{}

func GetByServer(factory ModelFactory) gin.HandlerFunc {
	return func(c *gin.Context) {
		serverID := c.Param("server_id")
		role := factory()
		if role == nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Factory function returned nil"})
			return
		}
		if err := db.GetDB().Where("server_id = ?", serverID).Find(role).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, role)
	}
}

func AddRoleToServer(factory ModelFactory) gin.HandlerFunc {
	return func(c *gin.Context) {
		serverID := c.Param("id")
		role := factory()
		if err := c.ShouldBindJSON(role); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}
		serverIDInt, _ := strconv.Atoi(serverID)
		role.(*models.Role).ServerID = uint(serverIDInt)
		if err := db.GetDB().Create(role).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusCreated, role)
	}
}
