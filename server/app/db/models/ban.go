package models

import (
	"gorm.io/gorm"
	"time"
)

type Ban struct {
	gorm.Model
	Reason     string    `gorm:"validate:required"`
	Duration   time.Time `gorm:"validate:required"`
	UserID     uint      `gorm:"not null"`
	User       User      `gorm:"foreignKey:UserID;references:ID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE"`
	ServerID   uint      `gorm:"not null"`
	Server     Server    `gorm:"foreignKey:ServerID;references:ID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE"
	BannedByID uint      `gorm:"not null"`
	BannedBy   User      `gorm:"foreignKey:BannedByID;references:ID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE"`
}