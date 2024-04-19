package routes

import (
    "app/controllers"
	"github.com/gin-gonic/gin"
	"app/db/models"
)

func OnServerRoutes(r *gin.Engine) {
	r.GET("/onServers", controllers.GetAll(func() interface{} { return &[]models.OnServer{} }))
	r.POST("/onServers", controllers.Create(func() interface{} { return &models.OnServer{} }))
	r.GET("/onServers/:id", controllers.Get(func() interface{} { return &models.OnServer{} }))
	r.PUT("/onServers/:id", controllers.Update(func() interface{} { return &models.OnServer{} }))
	r.DELETE("/onServers/:id", controllers.Delete(func() interface{} { return &models.OnServer{} }))
}
