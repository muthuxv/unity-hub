package routes

import (
    "app/controllers"
	"github.com/gin-gonic/gin"
	"app/db/models"
)

func InvitationRoutes(r *gin.Engine) {
	r.GET("/invitations", controllers.GetAll(func() interface{} { return &[]models.Invitation{} }))
	r.POST("/invitations", controllers.Create(func() interface{} { return &models.Invitation{} }))
	r.GET("/invitations/:id", controllers.Get(func() interface{} { return &models.Invitation{} }))
	r.PUT("/invitations/:id", controllers.Update(func() interface{} { return &models.Invitation{} }))
	r.DELETE("/invitations/:id", controllers.Delete(func() interface{} { return &models.Invitation{} }))
}
