package routes

import (
    "app/controllers"
	"github.com/gin-gonic/gin"
	"app/db/models"
)

func FriendRoutes(r *gin.Engine) {
	r.GET("/friends", controllers.GetAll(func() interface{} { return &[]models.Friend{} }))
	r.POST("/friends", controllers.Create(func() interface{} { return &models.Friend{} }))
	r.GET("/friends/:id", controllers.Get(func() interface{} { return &models.Friend{} }))
	r.PUT("/friends/:id", controllers.Update(func() interface{} { return &models.Friend{} }))
	r.DELETE("/friends/:id", controllers.Delete(func() interface{} { return &models.Friend{} }))
}
