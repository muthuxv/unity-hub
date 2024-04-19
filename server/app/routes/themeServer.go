package routes

import (
    "app/controllers"
	"github.com/gin-gonic/gin"
	"app/db/models"
)

func ThemeServerRoutes(r *gin.Engine) {
	r.GET("/themeServers", controllers.GetAll(func() interface{} { return &[]models.ThemeServer{} }))
	r.POST("/themeServers", controllers.Create(func() interface{} { return &models.ThemeServer{} }))
	r.GET("/themeServers/:id", controllers.Get(func() interface{} { return &models.ThemeServer{} }))
	r.PUT("/themeServers/:id", controllers.Update(func() interface{} { return &models.ThemeServer{} }))
	r.DELETE("/themeServers/:id", controllers.Delete(func() interface{} { return &models.ThemeServer{} }))
}
