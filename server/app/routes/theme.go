package routes

import (
    "app/controllers"
	"github.com/gin-gonic/gin"
	"app/db/models"
)

func ThemeRoutes(r *gin.Engine) {
	r.GET("/themes", controllers.GetAll(func() interface{} { return &[]models.Theme{} }))
	r.POST("/themes", controllers.Create(func() interface{} { return &models.Theme{} }))
	r.GET("/themes/:id", controllers.Get(func() interface{} { return &models.Theme{} }))
	r.PUT("/themes/:id", controllers.Update(func() interface{} { return &models.Theme{} }))
	r.DELETE("/themes/:id", controllers.Delete(func() interface{} { return &models.Theme{} }))
}
