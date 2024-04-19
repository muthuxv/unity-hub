package routes

import (
    "app/controllers"
	"github.com/gin-gonic/gin"
	"app/db/models"
)

func ReportRoutes(r *gin.Engine) {
	r.GET("/reports", controllers.GetAll(func() interface{} { return &[]models.Report{} }))
	r.POST("/reports", controllers.Create(func() interface{} { return &models.Report{} }))
	r.GET("/reports/:id", controllers.Get(func() interface{} { return &models.Report{} }))
	r.PUT("/reports/:id", controllers.Update(func() interface{} { return &models.Report{} }))
	r.DELETE("/reports/:id", controllers.Delete(func() interface{} { return &models.Report{} }))
}
