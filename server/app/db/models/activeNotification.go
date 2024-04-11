package models

import (
	"gorm.io/gorm"
)

type ActiveNotification struct {
	gorm.Model
	Status         bool `gorm:"not null"`
	UserID         uint `gorm:"not null"`
	User           User `gorm:"foreignKey:UserID;references:ID;constraint:OnUpdate:CASCADE,OnDelete:SET NULL;"`
	NotificationID uint `gorm:"not null"`
	Notification   Notification `gorm:"foreignKey:NotificationID;references:ID;constraint:OnUpdate:CASCADE,OnDelete:SET NULL;"`
}