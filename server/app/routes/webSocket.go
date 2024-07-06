package routes

import (
	"app/services"

	"github.com/gin-gonic/gin"
	"github.com/julienschmidt/httprouter"
)

func WebSocketRoutes(r *gin.Engine) {
	r.GET("/ws", func(c *gin.Context) {
		services.WsHandler(c.Writer, c.Request)
	})

	r.GET("/channels/:id/send", func(c *gin.Context) {
		services.ChannelWsHandler(c.Writer, c.Request, c.Param("id"))
	})

	r.GET("ws/servers/:id", func(c *gin.Context) {
		services.ServerWsHandler(c.Writer, c.Request, httprouter.Params{httprouter.Param{Key: "id", Value: c.Param("id")}})
	})

	r.POST("/ws/servers/:id/channels", func(c *gin.Context) {
		services.AddChannelHandler(c.Writer, c.Request, httprouter.Params{httprouter.Param{Key: "id", Value: c.Param("id")}})
	})
}
