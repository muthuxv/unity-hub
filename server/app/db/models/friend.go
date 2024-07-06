package models

import (
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Friend struct {
	ID uuid.UUID `gorm:"type:uuid;primaryKey"`
	gorm.Model
	Status  string    `gorm:"validate:required"`
	UserID1 uuid.UUID `gorm:"validate:required"`
	User1   User      `gorm:"foreignKey:UserID1;references:ID;"`
	UserID2 uuid.UUID `gorm:"validate:required"`
	User2   User      `gorm:"foreignKey:UserID2;references:ID;"`
}

func (f *Friend) BeforeCreate(tx *gorm.DB) (err error) {
	f.ID = uuid.New()
	return nil
}