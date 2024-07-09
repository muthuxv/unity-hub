package models

import (
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Report struct {
	ID uuid.UUID `gorm:"type:uuid;primaryKey"`
	gorm.Model
	Message         string    `gorm:"validate:required"`
	Status          string    `gorm:"validate:required"`
	MessageID       uuid.UUID `gorm:"validate:required"`
	ReportedMessage Message   `gorm:"foreignKey:MessageID;references:ID;"`
	UserID          uuid.UUID `gorm:"not null"`
	Reporter        User      `gorm:"foreignKey:UserID;references:ID;"`
	ServerID        uuid.UUID `gorm:"validate:required"`
	Server          Server    `gorm:"foreignKey:ServerID;references:ID;"`
}

func (r *Report) BeforeCreate(tx *gorm.DB) (err error) {
	r.ID = uuid.New()
	return nil
}
