package routes

import (
    "app/controllers"
	"github.com/gin-gonic/gin"
	"app/db/models"
)

func ActiveNotificationRoutes(r *gin.Engine) {
	r.GET("/activeNotifications", controllers.GetAll(func() interface{} { return &[]models.ActiveNotification{} }))
	r.POST("/activeNotifications", controllers.Create(func() interface{} { return &models.ActiveNotification{} }))
	r.GET("/activeNotifications/:id", controllers.Get(func() interface{} { return &models.ActiveNotification{} }))
	r.PUT("/activeNotifications/:id", controllers.Update(func() interface{} { return &models.ActiveNotification{} }))
	r.DELETE("/activeNotifications/:id", controllers.Delete(func() interface{} { return &models.ActiveNotification{} }))
}
