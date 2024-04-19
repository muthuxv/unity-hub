package routes

import (
    "app/controllers"
	"github.com/gin-gonic/gin"
	"app/db/models"
)

func ReactRoutes(r *gin.Engine) {
	r.GET("/reacts", controllers.GetAll(func() interface{} { return &[]models.React{} }))
	r.POST("/reacts", controllers.Create(func() interface{} { return &models.React{} }))
	r.GET("/reacts/:id", controllers.Get(func() interface{} { return &models.React{} }))
	r.PUT("/reacts/:id", controllers.Update(func() interface{} { return &models.React{} }))
	r.DELETE("/reacts/:id", controllers.Delete(func() interface{} { return &models.React{} }))
}
