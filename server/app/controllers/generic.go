package controllers

import (
	"app/db"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type ModelFactory func() interface{}

type PreloadField struct {
	Association string
	Fields      []string
}

func GetAll(factory ModelFactory, preloads ...PreloadField) gin.HandlerFunc {
	return func(c *gin.Context) {
		modelSlice := factory()
		query := db.GetDB().Model(modelSlice)

		for _, preload := range preloads {
			if len(preload.Fields) > 0 {
				query = query.Preload(preload.Association, func(db *gorm.DB) *gorm.DB {
					return db.Select(preload.Fields)
				})
			} else {
				query = query.Preload(preload.Association)
			}
		}

		if err := query.Find(modelSlice).Error; err != nil {
			c.Error(err)
			return
		}
		c.JSON(http.StatusOK, modelSlice)
	}
}

func Create(factory ModelFactory) gin.HandlerFunc {
	return func(c *gin.Context) {
		model := factory()
		if err := c.ShouldBindJSON(model); err != nil {
			c.Error(err)
			return
		}
		if err := db.GetDB().Create(model).Error; err != nil {
			c.Error(err)
			return
		}
		c.JSON(http.StatusCreated, model)
	}
}

func Get(factory ModelFactory, preloads ...PreloadField) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")

		// Vérification de l'UUID
		uid, err := uuid.Parse(id)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid UUID format"})
			return
		}

		model := factory()
		query := db.GetDB().Where("id = ?", uid)

		for _, preload := range preloads {
			if len(preload.Fields) > 0 {
				query = query.Preload(preload.Association, func(db *gorm.DB) *gorm.DB {
					return db.Select(preload.Fields)
				})
			} else {
				query = query.Preload(preload.Association)
			}
		}

		if err := query.First(model).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "UUID not found"})
			return
		}
		c.JSON(http.StatusOK, model)
	}
}

func Update(factory ModelFactory) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")

		// Vérification de l'UUID
		uid, err := uuid.Parse(id)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid UUID format"})
			return
		}

		model := factory()
		if err := db.GetDB().Where("id = ?", uid).First(model).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "UUID not found"})
			return
		}
		if err := c.ShouldBindJSON(model); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}
		if err := db.GetDB().Save(model).Error; err != nil {
			c.Error(err)
			return
		}
		c.JSON(http.StatusOK, model)
	}
}

func Delete(factory ModelFactory) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")

		// Vérification de l'UUID
		uid, err := uuid.Parse(id)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid UUID format"})
			return
		}

		model := factory()
		if err := db.GetDB().Where("id = ?", uid).First(model).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "UUID not found"})
			return
		}

		if err := db.GetDB().Where("id = ?", uid).Delete(model).Error; err != nil {
			c.Error(err)
			return
		}
		c.Status(http.StatusNoContent)
	}
}
