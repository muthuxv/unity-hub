package routes

import (
	"app/services"

	"github.com/gin-gonic/gin"
)

func AuthV2Routes(r *gin.Engine) {
	r.GET("/auth/github/callback", services.OAuthCallbackHandler("github"))
}
