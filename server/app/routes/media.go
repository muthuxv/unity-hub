package routes

import (
    "app/controllers"
	"app/services"
	"github.com/gin-gonic/gin"
	"app/db/models"
)

func MediaRoutes(r *gin.Engine) {
	r.GET("/medias", controllers.GetAll(func() interface{} { return &[]models.Media{} }))
	r.POST("/upload", services.UploadFile)
}
