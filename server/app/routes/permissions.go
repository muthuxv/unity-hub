package routes

import (
    "app/controllers"
	"github.com/gin-gonic/gin"
	"app/db/models"
)

func PermissionsRoutes(r *gin.Engine) {
	r.GET("/permissions", controllers.GetAll(func() interface{} { return &[]models.Permissions{} }))
	r.POST("/permissions", controllers.Create(func() interface{} { return &models.Permissions{} }))
	r.GET("/permissions/:id", controllers.Get(func() interface{} { return &models.Permissions{} }))
	r.PUT("/permissions/:id", controllers.Update(func() interface{} { return &models.Permissions{} }))
	r.DELETE("/permissions/:id", controllers.Delete(func() interface{} { return &models.Permissions{} }))
}
