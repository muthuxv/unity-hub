package models

import (
	"gorm.io/gorm"
)

type Tag struct {
	gorm.Model
	ID   uint   `gorm:"primaryKey"`
	Name string `gorm:"validate:required"`
}
