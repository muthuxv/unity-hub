package routes

import (
    "app/controllers"
	"github.com/gin-gonic/gin"
	"app/db/models"
)

func NotificationRoutes(r *gin.Engine) {
	r.GET("/notifications", controllers.GetAll(func() interface{} { return &[]models.Notification{} }))
	r.POST("/notifications", controllers.Create(func() interface{} { return &models.Notification{} }))
	r.GET("/notifications/:id", controllers.Get(func() interface{} { return &models.Notification{} }))
	r.PUT("/notifications/:id", controllers.Update(func() interface{} { return &models.Notification{} }))
	r.DELETE("/notifications/:id", controllers.Delete(func() interface{} { return &models.Notification{} }))
}
