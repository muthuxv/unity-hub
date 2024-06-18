package models

import (
	"gorm.io/gorm"
)

type Rule struct {
	gorm.Model
	Label string `gorm:"not null"`
}