package routes

import (
	"app/controllers"
	"app/db/models"
	"app/services"
	"github.com/gin-gonic/gin"
)

func ReportRoutes(r *gin.Engine) {
	r.GET("/reports", controllers.GetAll(func() interface{} { return &[]models.Report{} }))
	r.POST("/reports", controllers.Create(func() interface{} { return &models.Report{} }))
	r.GET("/reports/:id", controllers.Get(func() interface{} { return &models.Report{} }))
	r.PUT("/reports/:id", controllers.Update(func() interface{} { return &models.Report{} }))
	r.DELETE("/reports/:id", controllers.Delete(func() interface{} { return &models.Report{} }))

	r.GET("/reports/server/:serverId", services.GetReportsByServer())
}
