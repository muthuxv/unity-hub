package routes

import (
	"app/services"
	"github.com/gin-gonic/gin"
)

func VocalRoutes(r *gin.Engine) {
    r.POST("/webrtc/sdp", func(c *gin.Context) {
        services.SDPHandler(c.Writer, c.Request)
    })
    r.POST("/webrtc/ice", func(c *gin.Context) {
        services.ICECandidateHandler(c.Writer, c.Request)
    })
}
