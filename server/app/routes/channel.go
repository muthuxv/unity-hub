package routes

import (
	"app/controllers"
	"app/db/models"
	"app/services"

	"github.com/gin-gonic/gin"
)

func ChannelRoutes(r *gin.Engine) {
	r.GET("/channels", controllers.GetAll(func() interface{} { return &[]models.Channel{} }))
	r.POST("/channels", controllers.Create(func() interface{} { return &models.Channel{} }), controllers.GenerateLogChannelMiddlaware("created"))
	r.GET("/channels/:id", controllers.Get(func() interface{} { return &models.Channel{} }))
	r.PUT("/channels/:id", controllers.Update(func() interface{} { return &models.Channel{} }))
	r.DELETE("/channels/:id", controllers.Delete(func() interface{} { return &models.Channel{} }), controllers.GenerateLogChannelMiddlaware("deleted"))

	r.GET("/channels/:id/messages", services.GetChannelMessages())
	r.GET("/users/:id/channels", services.GetUserChannels())
}
