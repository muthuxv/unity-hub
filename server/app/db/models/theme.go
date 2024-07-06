package models

import (
	"github.com/google/uuid"
    "gorm.io/gorm"
)

type Theme struct {
	ID uuid.UUID `gorm:"type:uuid;primaryKey"`
    gorm.Model
    Label string `gorm:"validate:required"`
}

func (t *Theme) BeforeCreate(tx *gorm.DB) (err error) {
	t.ID = uuid.New()
	return nil
}