package models

import (
    "gorm.io/gorm"
    "time"
)

type Invitation struct {
    gorm.Model
    ID           uint      `gorm:"primaryKey"`
    Link         string    `gorm:"validate:required"`
    Expire       time.Time `gorm:"validate:required"`
    UserSenderID uint      `gorm:"validate:required"`
	UserSender   User `gorm:"foreignKey:UserSenderID;references:ID;"`
    UserReceiverID uint    `gorm:"validate:required"`
    UserReceiver User `gorm:"foreignKey:UserReceiverID;references:ID;"` 
    ServerID uint `gorm:"validate:required"` 
    Server Server `gorm:"foreignKey:ServerID;references:ID;"`
}
