package models

import (
    "gorm.io/gorm"
)

type ReactMessage struct {
    gorm.Model
    ID       uint `gorm:"primaryKey"`
    UserID   uint `gorm:"validate:required"`
	User    User    `gorm:"foreignKey:UserID;references:ID;"`
    ReactID  uint `gorm:"validate:required"`
	React   React   `gorm:"foreignKey:ReactID;references:ID;"`
    MessageID uint `gorm:"validate:required"`
    Message Message `gorm:"foreignKey:MessageID;references:ID;"` 
}
