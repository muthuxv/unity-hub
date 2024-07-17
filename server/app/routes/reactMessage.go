package routes

import (
	"app/controllers"
	"app/db/models"
	"app/services"

	"github.com/gin-gonic/gin"
)

func ReactMessageRoutes(r *gin.Engine) {
	r.GET("/reactMessages", controllers.GetAll(func() interface{} { return &[]models.ReactMessage{} }))
	r.GET("/reactMessages/:id", controllers.Get(func() interface{} { return &models.ReactMessage{} }))
	r.PUT("/reactMessages/:id", controllers.Update(func() interface{} { return &models.ReactMessage{} }))
	r.DELETE("/reactMessages/:id", controllers.Delete(func() interface{} { return &models.ReactMessage{} }))

	r.POST("/reactMessages", controllers.TokenAuthMiddleware("user"), services.CreateReactMessage())
}
