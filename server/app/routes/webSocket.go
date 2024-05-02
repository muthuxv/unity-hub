package routes

import (
	"app/services"
	"github.com/gin-gonic/gin"
)

func WebSocketRoutes(r *gin.Engine) {
	r.GET("/ws", func(c *gin.Context) {
        services.WsHandler(c.Writer, c.Request)
    })

	r.GET("/channels/:id/send", func(c *gin.Context) {
        services.ChannelWsHandler(c.Writer, c.Request, c.Param("id"))
    })
}
