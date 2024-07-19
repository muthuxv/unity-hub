package routes

import (
	"app/controllers"
	"app/db/models"
	"app/services"

	"github.com/gin-gonic/gin"
)

func InvitationRoutes(r *gin.Engine) {
	r.DELETE("/invitations/:id", controllers.TokenAuthMiddleware("user"), controllers.IsUserInInvitationMiddleware(), controllers.Delete(func() interface{} { return &models.Invitation{} }))

	r.POST("/invitations/server/:id", controllers.TokenAuthMiddleware("user"), controllers.IsUserOnServerMiddleware(), services.SendInvitation(false))
	r.GET("/invitations/user/:id", controllers.TokenAuthMiddleware("user"), controllers.IsOwner(), services.GetInvitationsByUser())
}
