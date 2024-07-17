package models

import (
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Channel struct {
	ID uuid.UUID `gorm:"type:uuid;primaryKey"`
	gorm.Model
	Name       string    `gorm:"validate:required"`
	Type       string    `gorm:"validate:required"`
	Permission string    `gorm:"validate:required"`
	ServerID   uuid.UUID `gorm:"validate:required"`
}

func (c *Channel) BeforeCreate(tx *gorm.DB) (err error) {
	c.ID = uuid.New()
	return nil
}
