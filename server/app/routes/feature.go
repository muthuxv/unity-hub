package routes

import (
	"app/controllers"
	"app/db/models"

	"github.com/gin-gonic/gin"
)

func FeatureRoutes(r *gin.Engine) {
	r.GET("/features", controllers.TokenAuthMiddleware("user"), controllers.GetAll(func() interface{} { return &[]models.Feature{} }))
	r.POST("/features", controllers.TokenAuthMiddleware("admin"), controllers.Create(func() interface{} { return &models.Feature{} }))
	r.GET("/features/:id", controllers.TokenAuthMiddleware("admin"), controllers.Get(func() interface{} { return &models.Feature{} }))
	r.PUT("/features/:id", controllers.TokenAuthMiddleware("admin"), controllers.Update(func() interface{} { return &models.Feature{} }))
	r.DELETE("/features/:id", controllers.TokenAuthMiddleware("admin"), controllers.Delete(func() interface{} { return &models.Feature{} }))
}
