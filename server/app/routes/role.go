package routes

import (
	"app/controllers"
	"app/db/models"
	"app/services"
	"github.com/gin-gonic/gin"
)

func RoleRoutes(r *gin.Engine) {
	r.GET("/roles", controllers.GetAll(func() interface{} { return &[]models.Role{} }))
	r.POST("/roles", controllers.PermissionMiddleware("createRole"), controllers.Create(func() interface{} { return &models.Role{} }))
	r.GET("/roles/:id", controllers.Get(func() interface{} { return &models.Role{} }))
	r.PUT("/roles/:id", controllers.Update(func() interface{} { return &models.Role{} }))
	r.DELETE("/roles/:id", controllers.Delete(func() interface{} { return &models.Role{} }))
	r.GET("/roles/server/:server_id", controllers.TokenAuthMiddleware("user"), services.GetByServer(func() interface{} { return &[]models.Role{} }))
	r.POST("/roles/server/:id/add", controllers.TokenAuthMiddleware("user"), services.AddRoleToServer(func() interface{} { return &models.Role{} }))
	
	r.GET("/roles/:id/permissions", services.GetRolePermissions)
	r.PUT("/roles/:id/permissions", services.UpdateRolePermissions)
}
