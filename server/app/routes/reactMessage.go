package routes

import (
	"app/controllers"
	"app/services"

	"github.com/gin-gonic/gin"
)

func ReactMessageRoutes(r *gin.Engine) {
	r.DELETE("/reactMessages/:id", controllers.TokenAuthMiddleware("user"), services.DeleteReactMessage())
	r.POST("/reactMessages", controllers.TokenAuthMiddleware("user"), services.CreateReactMessage())
}
