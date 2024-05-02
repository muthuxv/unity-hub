package models

import (
	"gorm.io/gorm"
)

type Server struct {
	gorm.Model
	ID         uint   `gorm:"primaryKey"`
	Name       string `gorm:"validate:required"`
	Visibility string `gorm:"validate:required"`
	MediaID    uint   `gorm:"validate:required"`
	Media      Media  `gorm:"foreignKey:MediaID;references:ID;"`
}
