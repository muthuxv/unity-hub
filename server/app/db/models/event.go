package models

import (
    "gorm.io/gorm"
    "time"
	"github.com/google/uuid"
)

type Event struct {
	ID uuid.UUID `gorm:"type:uuid;primaryKey"`
    gorm.Model
    Name string    `gorm:"validate:required"`
    Description string    `gorm:""`
    Date time.Time `gorm:"validate:required"`
}

func (e *Event) BeforeCreate(tx *gorm.DB) (err error) {
	e.ID = uuid.New()
	return nil
}