package routes

import (
    "app/controllers"
	"github.com/gin-gonic/gin"
	"app/db/models"
)

func LogsRoutes(r *gin.Engine) {
	r.GET("/logs", controllers.GetAll(func() interface{} { return &[]models.Logs{} }))
	r.POST("/logs", controllers.Create(func() interface{} { return &models.Logs{} }))
	r.GET("/logs/:id", controllers.Get(func() interface{} { return &models.Logs{} }))
	r.PUT("/logs/:id", controllers.Update(func() interface{} { return &models.Logs{} }))
	r.DELETE("/logs/:id", controllers.Delete(func() interface{} { return &models.Logs{} }))
}
