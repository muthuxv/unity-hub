package routes

import (
    "app/controllers"
	"github.com/gin-gonic/gin"
	"app/db/models"
)

func ReactMessageRoutes(r *gin.Engine) {
	r.GET("/reactMessages", controllers.GetAll(func() interface{} { return &[]models.ReactMessage{} }))
	r.POST("/reactMessages", controllers.Create(func() interface{} { return &models.ReactMessage{} }))
	r.GET("/reactMessages/:id", controllers.Get(func() interface{} { return &models.ReactMessage{} }))
	r.PUT("/reactMessages/:id", controllers.Update(func() interface{} { return &models.ReactMessage{} }))
	r.DELETE("/reactMessages/:id", controllers.Delete(func() interface{} { return &models.ReactMessage{} }))
}
