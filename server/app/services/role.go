package services

import (
	"app/db"
	"app/db/models"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
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
		serverIDInt, _ := uuid.Parse(serverID)
		role.(*models.Role).ServerID = serverIDInt
		if err := db.GetDB().Create(role).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusCreated, role)
	}
}

type PermissionResponse struct {
	Label string `json:"label"`
	Power int    `json:"power"`
}

func GetRolePermissions(c *gin.Context) {
	roleID := c.Param("id")
	roleUUID, err := uuid.Parse(roleID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid role ID"})
		return
	}

	var permissions []PermissionResponse
	// Effectuer la jointure interne et sélectionner les champs nécessaires
	if err := db.GetDB().Table("role_permissions").
		Select("permissions.label, role_permissions.power").
		Joins("inner join permissions on permissions.id = role_permissions.permissions_id").
		Where("role_permissions.role_id = ?", roleUUID).
		Scan(&permissions).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error fetching role permissions"})
		return
	}

	c.JSON(http.StatusOK, permissions)
}
