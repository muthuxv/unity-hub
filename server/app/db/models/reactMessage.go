package models

import (
	"github.com/google/uuid"
    "gorm.io/gorm"
)

type ReactMessage struct {
	ID uuid.UUID `gorm:"type:uuid;primaryKey"`
    gorm.Model
    UserID   uuid.UUID `gorm:"validate:required"`
	User    User    `gorm:"foreignKey:UserID;references:ID;"`
    ReactID  uuid.UUID `gorm:"validate:required"`
	React   React   `gorm:"foreignKey:ReactID;references:ID;"`
    MessageID uuid.UUID `gorm:"validate:required"`
    Message Message `gorm:"foreignKey:MessageID;references:ID;"` 
}

func (rm *ReactMessage) BeforeCreate(tx *gorm.DB) (err error) {
	rm.ID = uuid.New()
	return nil
}