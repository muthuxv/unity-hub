package models

import (
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Friend struct {
	gorm.Model
	ID      uint      `gorm:"primaryKey"`
	Status  string    `gorm:"validate:required"`
	UserID1 uuid.UUID `gorm:"validate:required"`
	User1   User      `gorm:"foreignKey:UserID1;references:ID;"`
	UserID2 uuid.UUID `gorm:"validate:required"`
	User2   User      `gorm:"foreignKey:UserID2;references:ID;"`
}
