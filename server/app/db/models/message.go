package models

import (
	"gorm.io/gorm"
)

type Message struct {
	gorm.Model
	ID        uint    `gorm:"primaryKey"`
	Content   string  `gorm:"validate:required"`
	Type      string  `gorm:"validate:required"`
	SentAt    string  `gorm:"validate:required"`
	UserID    uint    `gorm:"validate:required"`
	User      User    `gorm:"foreignKey:UserID;references:ID;"`
	ChannelID uint    `gorm:"validate:required"`
	Channel   Channel `gorm:"foreignKey:ChannelID;references:ID;"`
}
