package routes

import (
    "app/controllers"
	"github.com/gin-gonic/gin"
	"app/db/models"
)

func GroupRoutes(r *gin.Engine) {
	r.GET("/groups", controllers.GetAll(func() interface{} { return &[]models.Group{} }))
	r.POST("/groups", controllers.Create(func() interface{} { return &models.Group{} }))
	r.GET("/groups/:id", controllers.Get(func() interface{} { return &models.Group{} }))
	r.PUT("/groups/:id", controllers.Update(func() interface{} { return &models.Group{} }))
	r.DELETE("/groups/:id", controllers.Delete(func() interface{} { return &models.Group{} }))
}
