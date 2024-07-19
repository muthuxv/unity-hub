package routes

import (
	"app/controllers"
	"app/db/models"
	"app/services"

	"github.com/gin-gonic/gin"
)

func FriendRoutes(r *gin.Engine) {
	r.DELETE("/friends/:id", controllers.TokenAuthMiddleware("user"), controllers.Delete(func() interface{} { return &models.Friend{} }))

	r.POST("/friends/accept", controllers.TokenAuthMiddleware("user"), services.AcceptFriend())
	r.POST("/friends/refuse", controllers.TokenAuthMiddleware("user"), services.RefuseFriend())
	r.GET("/friends/search/:pseudo", controllers.TokenAuthMiddleware("user"), services.SearchUser())
	r.GET("/friends/users/:id", controllers.TokenAuthMiddleware("user"), services.GetFriendsByUser())
	r.GET("/friends/pending/:id", controllers.TokenAuthMiddleware("user"), services.GetPendingFriendsByUser())
	r.GET("/friends/sent/:id", controllers.TokenAuthMiddleware("user"), controllers.IsOwner(), services.GetPendingFriendsFromUser())
	r.POST("/friends/request", controllers.TokenAuthMiddleware("user"), services.CreateFriendRequest())
}
