package routes

import (
	"app/controllers"
	"app/db/models"
	"app/services"

	"github.com/gin-gonic/gin"
)

func TagRoutes(r *gin.Engine) {
	r.POST("/tags", controllers.Create(func() interface{} { return &models.Tag{} }))
	r.GET("/tags/:id", controllers.Get(func() interface{} { return &models.Tag{} }))
	r.PUT("/tags/:id", controllers.Update(func() interface{} { return &models.Tag{} }))
	r.DELETE("/tags/:id", controllers.Delete(func() interface{} { return &models.Tag{} }))

	r.GET("/tags", services.GetAllTags())
	r.GET("/tags/:id/servers", services.GetServersByTag())
}
