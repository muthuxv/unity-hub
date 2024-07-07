package routes

import (
	"app/controllers"
	"app/db/models"
	"app/services"

	"github.com/gin-gonic/gin"
)

func FeatureRoutes(r *gin.Engine) {
	r.GET("/features", controllers.GetAll(func() interface{} { return &[]models.Feature{} }))
	r.POST("/features", controllers.Create(func() interface{} { return &models.Feature{} }))
	r.GET("/features/:id", controllers.Get(func() interface{} { return &models.Feature{} }))
	r.PUT("/features/:id", controllers.Update(func() interface{} { return &models.Feature{} }))
	r.DELETE("/features/:id", controllers.Delete(func() interface{} { return &models.Feature{} }))

	r.GET("/featuress", services.GetAllFeatures())
}
