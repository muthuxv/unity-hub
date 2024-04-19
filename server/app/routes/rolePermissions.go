package routes

import (
    "app/controllers"
	"github.com/gin-gonic/gin"
	"app/db/models"
)

func RolePermissionsRoutes(r *gin.Engine) {
	r.GET("/rolePermissionss", controllers.GetAll(func() interface{} { return &[]models.RolePermissions{} }))
	r.POST("/rolePermissionss", controllers.Create(func() interface{} { return &models.RolePermissions{} }))
	r.GET("/rolePermissionss/:id", controllers.Get(func() interface{} { return &models.RolePermissions{} }))
	r.PUT("/rolePermissionss/:id", controllers.Update(func() interface{} { return &models.RolePermissions{} }))
	r.DELETE("/rolePermissionss/:id", controllers.Delete(func() interface{} { return &models.RolePermissions{} }))
}
