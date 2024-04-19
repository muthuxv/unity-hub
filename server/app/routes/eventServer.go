package routes

import (
    "app/controllers"
	"github.com/gin-gonic/gin"
	"app/db/models"
)

func EventServerRoutes(r *gin.Engine) {
	r.GET("/eventServers", controllers.GetAll(func() interface{} { return &[]models.EventServer{} }))
	r.POST("/eventServers", controllers.Create(func() interface{} { return &models.EventServer{} }))
	r.GET("/eventServers/:id", controllers.Get(func() interface{} { return &models.EventServer{} }))
	r.PUT("/eventServers/:id", controllers.Update(func() interface{} { return &models.EventServer{} }))
	r.DELETE("/eventServers/:id", controllers.Delete(func() interface{} { return &models.EventServer{} }))
}
