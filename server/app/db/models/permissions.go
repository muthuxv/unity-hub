package models

import (
	"github.com/google/uuid"
    "gorm.io/gorm"
)

type Permissions struct {
	ID uuid.UUID `gorm:"type:uuid;primaryKey"`
    gorm.Model
    Label string `gorm:"validate:required"`
}

func (p *Permissions) BeforeCreate(tx *gorm.DB) (err error) {
	p.ID = uuid.New()
	return nil
}