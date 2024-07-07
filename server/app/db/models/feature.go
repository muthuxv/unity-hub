package models

import (
	"gorm.io/gorm"
)

type Feature struct {
	gorm.Model
	ID     uint   `gorm:"primaryKey"`
	Name   string `gorm:"validate:required"`
	Status string `gorm:"validate:required"`
}
