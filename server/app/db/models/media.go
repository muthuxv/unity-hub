package models

import (
	"gorm.io/gorm"
)

type Media struct {
	gorm.Model
	FileName  string
	MimeType  string
	UserID    uint        `gorm:"constraint:OnUpdate:CASCADE,OnDelete:SET NULL;"`
	User      *User       `gorm:"foreignKey:UserID"`
}
