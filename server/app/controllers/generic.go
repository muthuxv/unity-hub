package controllers

import (
	"net/http"
	"github.com/gin-gonic/gin"
	"app/db"
)

type ModelFactory func() interface{}

func GetAll(factory ModelFactory) gin.HandlerFunc {
	return func(c *gin.Context) {
		modelSlice := factory()
		if err := db.GetDB().Find(modelSlice).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, modelSlice)
	}
}

func Create(factory ModelFactory) gin.HandlerFunc {
	return func(c *gin.Context) {
		model := factory()
		if err := c.ShouldBindJSON(model); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}
		if err := db.GetDB().Create(model).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusCreated, model)
	}
}

func Get(factory ModelFactory) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		model := factory()
		if err := db.GetDB().First(model, id).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "not found"})
			return
		}
		c.JSON(http.StatusOK, model)
	}
}

func Update(factory ModelFactory) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		model := factory()
		if err := db.GetDB().First(model, id).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "not found"})
			return
		}
		if err := c.ShouldBindJSON(model); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}
		db.GetDB().Save(model)
		c.JSON(http.StatusOK, model)
	}
}

func Delete(factory ModelFactory) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		model := factory()
		if err := db.GetDB().Delete(model, id).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "not found"})
			return
		}
		c.Status(http.StatusNoContent)
	}
}
