package routes

import (
    "app/controllers"
	"github.com/gin-gonic/gin"
	"app/db/models"
)

func GroupMemberRoutes(r *gin.Engine) {
	r.GET("/groupMembers", controllers.GetAll(func() interface{} { return &[]models.GroupMember{} }))
	r.POST("/groupMembers", controllers.Create(func() interface{} { return &models.GroupMember{} }))
	r.GET("/groupMembers/:id", controllers.Get(func() interface{} { return &models.GroupMember{} }))
	r.PUT("/groupMembers/:id", controllers.Update(func() interface{} { return &models.GroupMember{} }))
	r.DELETE("/groupMembers/:id", controllers.Delete(func() interface{} { return &models.GroupMember{} }))
}
