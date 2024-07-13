package controllers

import (
	"app/db"
	"net/http"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type ModelFactory func() interface{}

// GetAll handles GET requests to fetch all items.
// @Summary Get all items
// @Description Get a list of all items
// @Produce json
// @Success 200 {array} interface{}
// @Router /friends [get]
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

// Create handles POST requests to create a new item.
// @Summary Create a new item
// @Description Create a new item
// @Accept json
// @Produce json
// @Success 201 {object} interface{}
// @Router /friends [post]
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

// Get handles GET requests to fetch a single item by ID.
// @Summary Get an item by ID
// @Description Get a single item by ID
// @Produce json
// @Param id path string true "Item ID"
// @Success 200 {object} interface{}
// @Router /friends/{id} [get]
func Get(factory ModelFactory, preloads ...PreloadField) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")

		model := factory()
		query := db.GetDB().Where("id = ?", id)

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
			c.Error(err)
			return
		}
		c.JSON(http.StatusOK, model)
	}
}

// Update handles PUT requests to update an item by ID.
// @Summary Update an item by ID
// @Description Update an item by ID
// @Accept json
// @Produce json
// @Param id path string true "Item ID"
// @Success 200 {object} interface{}
// @Router /friends/{id} [put]
func Update(factory ModelFactory) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		model := factory()
		if err := db.GetDB().Where("id = ?", id).First(model).Error; err != nil {
			c.Error(err)
			return
		}
		if err := c.ShouldBindJSON(model); err != nil {
			c.Error(err)
			return
		}
		if err := db.GetDB().Save(model).Error; err != nil {
			c.Error(err)
			return
		}
		c.JSON(http.StatusOK, model)
	}
}

// Delete handles DELETE requests to delete an item by ID.
// @Summary Delete an item by ID
// @Description Delete an item by ID
// @Param id path string true "Item ID"
// @Success 204
// @Router /friends/{id} [delete]
func Delete(factory ModelFactory) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		model := factory()
		if err := db.GetDB().Where("id = ?", id).Delete(model).Error; err != nil {
			c.Error(err)
			return
		}
		c.Status(http.StatusNoContent)
	}
}
