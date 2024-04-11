package main

import (
    "app/routes"
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

    r.Run(":8080")
}
