package routes

import (
    "app/controllers"
	"github.com/gin-gonic/gin"
	"app/db/models"
	"app/services"
)

func ChannelRoutes(r *gin.Engine) {
	r.GET("/channels", controllers.GetAll(func() interface{} { return &[]models.Channel{} }))
	r.POST("/channels", controllers.Create(func() interface{} { return &models.Channel{} }))
	r.GET("/channels/:id", controllers.Get(func() interface{} { return &models.Channel{} }))
	r.PUT("/channels/:id", controllers.Update(func() interface{} { return &models.Channel{} }))
	r.DELETE("/channels/:id", controllers.Delete(func() interface{} { return &models.Channel{} }))

	r.GET("/channels/:id/messages", services.GetChannelMessages())
}
