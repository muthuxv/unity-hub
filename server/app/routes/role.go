package routes

import (
    "app/controllers"
	"github.com/gin-gonic/gin"
	"app/db/models"
)

func RoleRoutes(r *gin.Engine) {
	r.GET("/roles", controllers.GetAll(func() interface{} { return &[]models.Role{} }))
	r.POST("/roles", controllers.Create(func() interface{} { return &models.Role{} }))
	r.GET("/roles/:id", controllers.Get(func() interface{} { return &models.Role{} }))
	r.PUT("/roles/:id", controllers.Update(func() interface{} { return &models.Role{} }))
	r.DELETE("/roles/:id", controllers.Delete(func() interface{} { return &models.Role{} }))
}
