package routes

import (
	"app/controllers"
	"app/db/models"
	"app/services"

	"github.com/gin-gonic/gin"
)

func TagRoutes(r *gin.Engine) {
	r.GET("/tags/:id", controllers.TokenAuthMiddleware("admin"), controllers.Get(func() interface{} { return &models.Tag{} }))
	r.PUT("/tags/:id", controllers.TokenAuthMiddleware("admin"), controllers.Update(func() interface{} { return &models.Tag{} }))
	r.DELETE("/tags/:id", controllers.TokenAuthMiddleware("admin"), controllers.Delete(func() interface{} { return &models.Tag{} }))

	r.POST("/tags", controllers.TokenAuthMiddleware("user"), services.CreateTag())
	r.GET("/tags", controllers.TokenAuthMiddleware("user"), services.GetAllTags())
}
