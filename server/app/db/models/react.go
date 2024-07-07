package models

import (
	"github.com/google/uuid"
    "gorm.io/gorm"
)

type React struct {
	ID uuid.UUID `gorm:"type:uuid;primaryKey"`
    gorm.Model
    Name string `gorm:"validate:required"`
}

func (r *React) BeforeCreate(tx *gorm.DB) (err error) {
	r.ID = uuid.New()
	return nil
}