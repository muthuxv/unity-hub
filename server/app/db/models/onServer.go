package models

import (
	"gorm.io/gorm"
)

type OnServer struct {
	gorm.Model
	ID       uint   `gorm:"primaryKey"`
	UserID   uint   `gorm:"validate:required"`
	User     User   `gorm:"foreignKey:UserID;references:ID;"`
	ServerID uint   `gorm:"validate:required"`
	Server   Server `gorm:"foreignKey:ServerID;references:ID;"`
}
