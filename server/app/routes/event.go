package routes

import (
    "app/controllers"
	"github.com/gin-gonic/gin"
	"app/db/models"
)

func EventRoutes(r *gin.Engine) {
	r.GET("/events", controllers.GetAll(func() interface{} { return &[]models.Event{} }))
	r.POST("/events", controllers.Create(func() interface{} { return &models.Event{} }))
	r.GET("/events/:id", controllers.Get(func() interface{} { return &models.Event{} }))
	r.PUT("/events/:id", controllers.Update(func() interface{} { return &models.Event{} }))
	r.DELETE("/events/:id", controllers.Delete(func() interface{} { return &models.Event{} }))
}
