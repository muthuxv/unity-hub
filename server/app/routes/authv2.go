package routes

import (
	"github.com/gin-gonic/gin"
	"app/services"
)

func AuthV2Routes(r *gin.Engine) {
	// r.GET("/auth/google/callback", services.OAuthCallbackHandler("google"))
	r.GET("/auth/github/callback", services.OAuthCallbackHandler("github"))
}