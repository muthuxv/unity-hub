package routes

import (
	"app/controllers"
	"app/db/models"
	"app/services"

	"github.com/gin-gonic/gin"
)

func FriendRoutes(r *gin.Engine) {
	r.GET("/friends", controllers.GetAll(func() interface{} { return &[]models.Friend{} }))
	r.POST("/friends", controllers.Create(func() interface{} { return &models.Friend{} }))
	r.GET("/friends/:id", controllers.Get(func() interface{} { return &models.Friend{} }))
	r.PUT("/friends/:id", controllers.Update(func() interface{} { return &models.Friend{} }))
	r.DELETE("/friends/:id", controllers.Delete(func() interface{} { return &models.Friend{} }))

	r.POST("/friends/accept", services.AcceptFriend())
	r.POST("/friends/refuse", services.RefuseFriend())
	r.GET("/friends/search/:pseudo", services.SearchUser())
	r.GET("/friends/users/:id", services.GetFriendsByUser())
	r.GET("/friends/pending/:id", services.GetPendingFriendsByUser())
	r.GET("/friends/sent/:id", services.GetPendingFriendsFromUser())
	r.POST("/friends/request", services.CreateFriendRequest())
}
