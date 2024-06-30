package services

import (
	"app/db"
	"app/db/models"
	"net/http"

	"github.com/gin-gonic/gin"
)

func GetAllFeatures() gin.HandlerFunc {
	return func(c *gin.Context) {
		var features []models.Feature
		if err := db.GetDB().Find(&features).Error; err != nil {
			c.Error(err)
			return
		}

		c.JSON(http.StatusOK, features)
	}

}
