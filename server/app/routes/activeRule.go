package routes

import (
    "app/controllers"
	"github.com/gin-gonic/gin"
	"app/db/models"
)

func ActiveRuleRoutes(r *gin.Engine) {
	r.GET("/activeRules", controllers.GetAll(func() interface{} { return &[]models.ActiveRule{} }))
	r.POST("/activeRules", controllers.Create(func() interface{} { return &models.ActiveRule{} }))
	r.GET("/activeRules/:id", controllers.Get(func() interface{} { return &models.ActiveRule{} }))
	r.PUT("/activeRules/:id", controllers.Update(func() interface{} { return &models.ActiveRule{} }))
	r.DELETE("/activeRules/:id", controllers.Delete(func() interface{} { return &models.ActiveRule{} }))
}
