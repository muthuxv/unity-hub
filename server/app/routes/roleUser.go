package routes

import (
    "app/controllers"
	"github.com/gin-gonic/gin"
	"app/db/models"
)

func RoleUserRoutes(r *gin.Engine) {
	r.GET("/roleUsers", controllers.GetAll(func() interface{} { return &[]models.RoleUser{} }))
	r.POST("/roleUsers", controllers.Create(func() interface{} { return &models.RoleUser{} }))
	r.GET("/roleUsers/:id", controllers.Get(func() interface{} { return &models.RoleUser{} }))
	r.PUT("/roleUsers/:id", controllers.Update(func() interface{} { return &models.RoleUser{} }))
	r.DELETE("/roleUsers/:id", controllers.Delete(func() interface{} { return &models.RoleUser{} }))
}
