package routes

import (
	"app/controllers"
	"app/db/models"
	"app/services"

	"github.com/gin-gonic/gin"
)

func UserRoutes(r *gin.Engine) {
	r.GET("/users", controllers.TokenAuthMiddleware("admin"), controllers.GetAll(func() interface{} { return &[]models.User{} }))
	r.GET("/users/:id", controllers.TokenAuthMiddleware("user"), controllers.IsOwner(), controllers.Get(func() interface{} { return &models.User{} }))
	//r.PUT("/users/:id", controllers.FilterBodyMiddleware("role", "isVerified", "verificationToken"), controllers.Update(func() interface{} { return &models.User{} }))
	r.DELETE("/users/:id", controllers.Delete(func() interface{} { return &models.User{} }))

	r.POST("/register", services.Register())
	r.GET("/verify/:token", services.VerifyAccount())
	r.PUT("/users/:id", controllers.TokenAuthMiddleware("user"), controllers.IsOwner(), services.UpdateUserData())
	r.PUT("/users/:id/admin-update", controllers.TokenAuthMiddleware("admin"), services.UpdateUserAdmin())
	r.POST("/login", services.Login())
	r.PUT("/users/:id/change-password", controllers.TokenAuthMiddleware("user"), controllers.IsOwner(), services.ChangePassword())
	r.PUT("/fcm-token", controllers.TokenAuthMiddleware("user"), services.RegisterFcmToken())
	r.GET("/users/pseudo/:pseudo", controllers.TokenAuthMiddleware("user"), services.GetUserByPseudo())
	r.POST("/users", controllers.TokenAuthMiddleware("admin"), services.CreateUserByAdmin())
}
