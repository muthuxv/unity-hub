package main

import (
    "app/routes"
    "app/controllers"
    "github.com/gin-gonic/gin"
	"app/db"
)

func initDb() {
    db.InitDB()
    db.MakeMigrations()
}

func main() {
	initDb()

    r := gin.Default()

    r.Use(controllers.ErrorHandling())

	r.GET("/", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"message": "Hello world!",
		})
	})

    routes.MediaRoutes(r)
    routes.UserRoutes(r)
    routes.NotificationRoutes(r)
    routes.ActiveNotificationRoutes(r)
    routes.WebSocketRoutes(r)
    routes.AuthV2Routes(r)

    r.Run(":8080")
}
