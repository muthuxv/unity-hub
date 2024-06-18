package routes

import (
    "app/controllers"
	"github.com/gin-gonic/gin"
	"app/db/models"
)

func BanRoutes(r *gin.Engine) {
	r.GET("/bans", controllers.GetAll(func() interface{} { return &[]models.Ban{} }))
	r.POST("/bans", controllers.Create(func() interface{} { return &models.Ban{} }))
	r.GET("/bans/:id", controllers.Get(func() interface{} { return &models.Ban{} }))
	r.PUT("/bans/:id", controllers.Update(func() interface{} { return &models.Ban{} }))
	r.DELETE("/bans/:id", controllers.Delete(func() interface{} { return &models.Ban{} }))
}
