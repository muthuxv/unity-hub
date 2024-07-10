package routes

import (
	"app/controllers"
	"app/db/models"
	"app/services"

	"github.com/gin-gonic/gin"
)

func GroupRoutes(r *gin.Engine) {
	r.GET("/groups", controllers.GetAll(func() interface{} { return &[]models.Group{} }, controllers.PreloadField{Association: "Members", Fields: []string{"id", "pseudo", "profile"}}, controllers.PreloadField{Association: "Channel"}))
	r.POST("/groups", controllers.Create(func() interface{} { return &models.Group{} }))
	r.GET("/groups/:id", controllers.Get(func() interface{} { return &models.Group{} }))
	r.PUT("/groups/:id", controllers.Update(func() interface{} { return &models.Group{} }))
	r.DELETE("/groups/:id", controllers.Delete(func() interface{} { return &models.Group{} }))

	r.POST("/groups/private/:userID", services.CreateOrGetDM())
	r.POST("groups/public/:userID", services.CreatePublicGroup())
	r.GET("/groups/:id/members", services.GetGroupMembers())
	r.DELETE("/groups/:id/members/:userID", services.RemoveGroupMember())
	r.GET("/groups/users/:userID", services.GetUserGroups())
}
