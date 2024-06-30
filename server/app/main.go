package main

import (
	"app/controllers"
	"app/db"
	"app/routes"

	"github.com/gin-gonic/gin"
)

func initDb() {
	db.InitDB()
	db.MakeMigrations()
}

func main() {
	initDb()

	r := gin.Default()

	// Configuration CORS
	r.Use(func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
		c.Writer.Header().Set("Access-Control-Expose-Headers", "Content-Length")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(200)
			return
		}

		c.Next()
	})

	r.Use(controllers.ErrorHandling())

	r.GET("/", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"message": "Hello world!",
		})
	})

	/*models*/
	routes.MediaRoutes(r)
	routes.UserRoutes(r)
	routes.ChannelRoutes(r)
	routes.EventRoutes(r)
	routes.EventServerRoutes(r)
	routes.FriendRoutes(r)
	routes.InvitationRoutes(r)
	routes.LogsRoutes(r)
	routes.MessageRoutes(r)
	routes.OnServerRoutes(r)
	routes.PermissionsRoutes(r)
	routes.ReactRoutes(r)
	routes.ReactMessageRoutes(r)
	routes.ReportRoutes(r)
	routes.RoleRoutes(r)
	routes.RolePermissionsRoutes(r)
	routes.RoleUserRoutes(r)
	routes.ServerRoutes(r)
	routes.TagRoutes(r)
	routes.FeatureRoutes(r)
	routes.ThemeRoutes(r)
	routes.ThemeServerRoutes(r)
	routes.NotificationRoutes(r)
	routes.ActiveNotificationRoutes(r)
	/*workers*/
	routes.WebSocketRoutes(r)
	routes.AuthV2Routes(r)
	routes.VocalRoutes(r)

	//uploads
	r.Static("/uploads", "./upload")

	r.Run(":8080")
}
