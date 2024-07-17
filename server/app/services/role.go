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

func UpdateRolePermissions(c *gin.Context) {
	roleID := c.Param("id")
	roleUUID, err := uuid.Parse(roleID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid role ID"})
		return
	}

	availablePermissions := map[string]struct{}{
		"createChannel":  {},
		"sendMessage":    {},
		"accessChannel":  {},
		"banUser":        {},
		"kickUser":       {},
		"createRole":     {},
		"accessLog":      {},
		"accessReport":   {},
		"profileServer":  {},
		"editChannel":    {},
	}

	var requestBody map[string]int
	if err := c.BindJSON(&requestBody); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	for key := range availablePermissions {
		power, exists := requestBody[key]
		if !exists || power < 0 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Missing parameters"})
			return
		}
	}

	tx := db.GetDB().Begin()

	var updatedPermissions []PermissionResponse

	for label, power := range requestBody {
		var permission models.Permissions
		if err := tx.Where("label = ?", label).First(&permission).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Error fetching permission"})
			return
		}

		var rolePermission models.RolePermissions
		if err := tx.Where("role_id = ? AND permissions_id = ?", roleUUID, permission.ID).First(&rolePermission).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Error fetching role permission"})
			return
		}

		rolePermission.Power = power
		if err := tx.Save(&rolePermission).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Error updating role permission"})
			return
		}

		updatedPermissions = append(updatedPermissions, PermissionResponse{
			Label: label,
			Power: power,
		})
	}

	tx.Commit()
	c.JSON(http.StatusOK, updatedPermissions)
}