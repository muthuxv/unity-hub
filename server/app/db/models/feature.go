package models

import (
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Feature struct {
	gorm.Model
	ID     uuid.UUID `gorm:"type:uuid;primaryKey"`
	Name   string    `gorm:"unique;validate:required"`
	Status string    `gorm:"validate:required"`
}

func (f *Feature) BeforeCreate(tx *gorm.DB) (err error) {
	f.ID = uuid.New()
	return nil
}
