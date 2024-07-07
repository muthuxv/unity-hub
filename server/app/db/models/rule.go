package models

import (
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Rule struct {
	ID uuid.UUID `gorm:"type:uuid;primaryKey"`
	gorm.Model
	Label string `gorm:"not null"`
}

func (r *Rule) BeforeCreate(tx *gorm.DB) (err error) {
	r.ID = uuid.New()
	return nil
}