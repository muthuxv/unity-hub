package routes

import (
    "app/controllers"
	"app/services"
	"github.com/gin-gonic/gin"
	"app/db/models"
)

func UserRoutes(r *gin.Engine) {
	r.GET("/users", controllers.TokenAuthMiddleware("admin"), controllers.GetAll(func() interface{} { return &[]models.User{} }))
	r.GET("/users/:id", controllers.TokenAuthMiddleware("user"), controllers.IsOwner(), controllers.Get(func() interface{} { return &models.User{} }))
	r.PUT("/users/:id", controllers.FilterBodyMiddleware("role"), controllers.Update(func() interface{} { return &models.User{} }))
	r.DELETE("/users/:id", controllers.Delete(func() interface{} { return &models.User{} }))
	
	r.POST("/register", services.Register())
	r.GET("/verify/:token", services.VerifyAccount())
	r.POST("/login", services.Login())
}
