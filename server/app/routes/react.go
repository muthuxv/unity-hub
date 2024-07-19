package routes

import (
	"app/controllers"
	"app/db/models"

	"github.com/gin-gonic/gin"
)

func ReactRoutes(r *gin.Engine) {
	r.GET("/reacts", controllers.GetAll(func() interface{} { return &[]models.React{} }))
}
