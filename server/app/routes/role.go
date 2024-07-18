package routes

import (
	"app/controllers"
	"app/db/models"
	"app/services"
	"github.com/gin-gonic/gin"
)

func RoleRoutes(r *gin.Engine) {
	r.PUT("/roles/:id", controllers.Update(func() interface{} { return &models.Role{} }))
	r.DELETE("/roles/:id", controllers.Delete(func() interface{} { return &models.Role{} }))
	r.GET("/roles/server/:server_id", controllers.TokenAuthMiddleware("user"), services.GetByServer(func() interface{} { return &[]models.Role{} }))
	r.POST("/roles/server/:id/add", controllers.TokenAuthMiddleware("user"), services.AddRoleToServer(func() interface{} { return &models.Role{} }))
}
