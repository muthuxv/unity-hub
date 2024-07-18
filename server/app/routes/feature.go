package routes

import (
	"app/controllers"
	"app/db/models"

	"app/services"

	"github.com/gin-gonic/gin"
)

func FeatureRoutes(r *gin.Engine) {
	r.GET("/features", controllers.TokenAuthMiddleware("user"), controllers.GetAll(func() interface{} { return &[]models.Feature{} }))
	r.GET("/features/:id", controllers.TokenAuthMiddleware("admin"), controllers.Get(func() interface{} { return &models.Feature{} }))
	r.DELETE("/features/:id", controllers.TokenAuthMiddleware("admin"), controllers.Delete(func() interface{} { return &models.Feature{} }))

	r.POST("/features", controllers.TokenAuthMiddleware("admin"), services.CreateFeature())
	r.PUT("/features/:id", controllers.TokenAuthMiddleware("admin"), services.UpdateFeature())
}
