package routes

import (
	"app/controllers"
	"app/db/models"

	"github.com/gin-gonic/gin"
)

func LogsRoutes(r *gin.Engine) {
	r.GET("/logs", controllers.TokenAuthMiddleware("admin"), controllers.GetAll(func() interface{} { return &[]models.Logs{} }))
}
