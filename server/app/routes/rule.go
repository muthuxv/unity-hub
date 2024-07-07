package routes

import (
    "app/controllers"
	"github.com/gin-gonic/gin"
	"app/db/models"
)

func RuleRoutes(r *gin.Engine) {
	r.GET("/rules", controllers.GetAll(func() interface{} { return &[]models.Rule{} }))
	r.POST("/rules", controllers.Create(func() interface{} { return &models.Rule{} }))
	r.GET("/rules/:id", controllers.Get(func() interface{} { return &models.Rule{} }))
	r.PUT("/rules/:id", controllers.Update(func() interface{} { return &models.Rule{} }))
	r.DELETE("/rules/:id", controllers.Delete(func() interface{} { return &models.Rule{} }))
}
