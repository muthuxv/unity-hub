package models

import (
	"github.com/google/uuid"
    "gorm.io/gorm"
)

type Role struct {
	ID uuid.UUID `gorm:"type:uuid;primaryKey"`
    gorm.Model
    Label    string `gorm:"validate:required"`
    ServerID uuid.UUID   `gorm:"validate:required"`
    Server Server `gorm:"foreignKey:ServerID;references:ID;"`
}

func (r *Role) BeforeCreate(tx *gorm.DB) (err error) {
	r.ID = uuid.New()
	return nil
}