package routes

import (
	"app/services"
	"github.com/gin-gonic/gin"
)

func WebSocketRoutes(r *gin.Engine) {
	r.GET("/ws", func(c *gin.Context) {
        services.WsHandler(c.Writer, c.Request)
    })
}
