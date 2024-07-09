package models

import (
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Tag struct {
	ID uuid.UUID `gorm:"type:uuid;primaryKey"`
	gorm.Model
	Name string `gorm:"validate:required"`
}
