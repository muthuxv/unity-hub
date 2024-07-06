package models

import (
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Media struct {
	gorm.Model
	ID       uint `gorm:"primaryKey"`
	FileName string
	MimeType string
	UserID   uuid.UUID `gorm:"constraint:OnUpdate:CASCADE,OnDelete:SET NULL;"`
	User     *User     `gorm:"foreignKey:UserID"`
}
