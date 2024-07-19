package routes

import (
	"app/controllers"
	"app/db/models"
	"app/services"

	"github.com/gin-gonic/gin"
)

func GroupRoutes(r *gin.Engine) {
	r.GET("/groups/:id", controllers.TokenAuthMiddleware("user"), controllers.IsGroupMemberMiddleware(), controllers.Get(func() interface{} { return &models.Group{} }, controllers.PreloadField{Association: "Members", Fields: []string{"id", "pseudo", "profile"}}, controllers.PreloadField{Association: "Channel"}))

	r.POST("/groups/private/:userID", controllers.TokenAuthMiddleware("user"), services.CreateOrGetDM())
	r.POST("groups/public/:userID", controllers.TokenAuthMiddleware("user"), services.CreatePublicGroup())
	r.DELETE("/groups/:id/members/:userID", controllers.TokenAuthMiddleware("user"), controllers.IsGroupOwnerMiddleware(), services.RemoveGroupMember())
	r.GET("/groups/users/:id", controllers.TokenAuthMiddleware("user"), controllers.IsOwner(), services.GetUserGroups())
}
