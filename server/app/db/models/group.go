package models

import (
	"gorm.io/gorm"
)

type Group struct {
	gorm.Model
	Type      string   `gorm:"validate:required"`
	ChannelID uint     `gorm:"not null"`
	Channel   *Channel `gorm:"foreignKey:ChannelID;references:ID;constraint:OnUpdate:CASCADE,OnDelete:SET NULL"`
}
