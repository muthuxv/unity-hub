package routes

import (
	"app/controllers"
	"app/db/models"
	"app/services"

	"github.com/gin-gonic/gin"
)

func ServerRoutes(r *gin.Engine) {
	r.GET("/servers", controllers.GetAll(func() interface{} { return &[]models.Server{} }))
	r.POST("/servers", controllers.Create(func() interface{} { return &models.Server{} }))
	r.GET("/servers/:id", controllers.Get(func() interface{} { return &models.Server{} }))
	r.PUT("/servers/:id", controllers.Update(func() interface{} { return &models.Server{} }))
	r.DELETE("/servers/:id", controllers.Delete(func() interface{} { return &models.Server{} }))

	r.POST("/servers/create", controllers.TokenAuthMiddleware("user"), services.NewServer())
	r.POST("/servers/:id/join", controllers.TokenAuthMiddleware("user"), services.JoinServer())
	r.DELETE("/servers/:id/leave", controllers.TokenAuthMiddleware("user"), services.LeaveServer())
	r.GET("/servers/users/:id", controllers.TokenAuthMiddleware("user"), services.GetServersByUser())
	r.GET("/servers/:id/members", services.GetServerMembers())
	r.GET("/servers/:id/channels", services.GetServerChannels())
	r.GET("/servers/:id/logs", services.GetServerLogs())
}
