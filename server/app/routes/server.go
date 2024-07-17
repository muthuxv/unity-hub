package routes

import (
	"app/controllers"
	"app/db/models"
	"app/services"

	"github.com/gin-gonic/gin"
)

func ServerRoutes(r *gin.Engine) {
	r.POST("/servers", controllers.Create(func() interface{} { return &models.Server{} }))

	r.GET("/servers", controllers.TokenAuthMiddleware("user"), services.GetAllServers())
	r.GET("/servers/search", services.SearchServerByName())
	r.GET("/servers/:id", services.GetServerByID())
	r.PUT("/servers/:id", services.UpdateServerByID())
	r.GET("/servers/public/available/:id", services.GetPublicAvailableServers())
	r.POST("/servers/create", controllers.TokenAuthMiddleware("user"), services.NewServer())
	r.POST("/servers/:id/join", controllers.TokenAuthMiddleware("user"), controllers.GenerateLogMiddleware("joined"), services.JoinServer())
	r.DELETE("/servers/:id/leave", controllers.TokenAuthMiddleware("user"), controllers.GenerateLogMiddleware("left"), services.LeaveServer())
	r.GET("/servers/users/:id", controllers.TokenAuthMiddleware("user"), services.GetServersByUser())
	r.GET("/servers/:id/members", services.GetServerMembers())
	r.GET("/servers/:id/channels", services.GetServerChannels())
	r.GET("/servers/:id/logs", controllers.PermissionMiddleware("accessLog"), services.GetServerLogs())
	r.GET("/servers/:id/bans", services.GetServerBans())
	r.GET("/servers/friend/:friendID", controllers.TokenAuthMiddleware("user"), services.GetServersFriendNotIn())
	r.POST("/servers/:id/ban/users/:userID", controllers.TokenAuthMiddleware("user"), controllers.GenerateLogBanMiddlaware(), services.BanUser())
	r.DELETE("/servers/:id/unban/users/:userID", controllers.TokenAuthMiddleware("user"), services.UnbanUser())
	r.DELETE("/servers/:id", controllers.TokenAuthMiddleware("user"), services.DeleteServerByID())
}
