package routes

import (
    "app/controllers"
	"github.com/gin-gonic/gin"
	"app/db/models"
)

func ServerRoutes(r *gin.Engine) {
	r.GET("/servers", controllers.GetAll(func() interface{} { return &[]models.Server{} }))
	r.POST("/servers", controllers.Create(func() interface{} { return &models.Server{} }))
	r.GET("/servers/:id", controllers.Get(func() interface{} { return &models.Server{} }))
	r.PUT("/servers/:id", controllers.Update(func() interface{} { return &models.Server{} }))
	r.DELETE("/servers/:id", controllers.Delete(func() interface{} { return &models.Server{} }))
}
