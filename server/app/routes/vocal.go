package routes

import (
	"app/services"

	"github.com/gin-gonic/gin"
)

func VocalRoutes(r *gin.Engine) {
	r.GET("/channels/:id/connect", services.ConnectToChannel)
}
