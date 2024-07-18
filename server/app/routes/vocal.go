package routes

import (
  "app/controllers"
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
  r.GET("/webrtc/users", controllers.TokenAuthMiddleware("user"), func(c *gin.Context) {
    services.GetUsersInChannel(c.Writer, c.Request)
  })
}
