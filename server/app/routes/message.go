package routes

import (
	"app/controllers"
	"app/db/models"
	"app/services"

	"github.com/gin-gonic/gin"
)

func MessageRoutes(r *gin.Engine) {
	r.GET("/messages", controllers.GetAll(func() interface{} { return &[]models.Message{} }))
	r.POST("/messages", controllers.Create(func() interface{} { return &models.Message{} }))
	r.GET("/messages/:id", controllers.Get(func() interface{} { return &models.Message{} }))
	r.PUT("/messages/:id", controllers.Update(func() interface{} { return &models.Message{} }))
	r.DELETE("/messages/:id", controllers.Delete(func() interface{} { return &models.Message{} }))

	r.GET("/messages/:id/reactions", services.GetMessageReactions())
}
