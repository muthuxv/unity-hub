package models

import (
	"gorm.io/gorm"
)

type Notification struct {
	gorm.Model
	Type string `gorm:"not null"`
}