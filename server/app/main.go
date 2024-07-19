package main

import (
	"app/controllers"
	"app/db"
	_ "app/docs"
	"app/routes"

	"github.com/gin-gonic/gin"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
)

func initDb() {
	db.InitDB()
	db.MakeMigrations()
}

// @title Swagger API pour le projet Go
// @version 1.0
// @description Cette API permet d'interagir avec le projet Go.
// @host localhost:8080
// @BasePath /
func main() {
	gin.SetMode(gin.ReleaseMode)

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
	routes.ServerRoutes(r)
	routes.TagRoutes(r)
	routes.FeatureRoutes(r)
	routes.GroupRoutes(r)
	/*workers*/
	routes.WebSocketRoutes(r)
	routes.AuthV2Routes(r)
	routes.VocalRoutes(r)

	// Swagger
	r.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

	//uploads
	r.Static("/uploads", "./upload")

	r.Run(":8080")
}
