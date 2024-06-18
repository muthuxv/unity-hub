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
	Tags       []Tag  `gorm:"many2many:server_tags;"`
	UserID     uint   `gorm:"not null"`
	User       User   `gorm:"foreignKey:UserID;references:ID;constraint:OnUpdate:CASCADE,OnDelete:SET NULL"`
}
