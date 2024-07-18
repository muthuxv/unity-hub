package routes

import (
	"app/controllers"
	"app/db/models"
	"app/services"

	"github.com/gin-gonic/gin"
)

func ReactMessageRoutes(r *gin.Engine) {
	r.DELETE("/reactMessages/:id", controllers.TokenAuthMiddleware("user"), controllers.Delete(func() interface{} { return &models.ReactMessage{} }))

	r.POST("/reactMessages", controllers.TokenAuthMiddleware("user"), services.CreateReactMessage())
}
