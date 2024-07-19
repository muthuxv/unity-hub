package models

import (
	"github.com/google/uuid"
    "gorm.io/gorm"
)

type RoleUser struct {
	ID uuid.UUID `gorm:"type:uuid;primaryKey"`
    gorm.Model
    UserID uuid.UUID `gorm:"validate:required"` 
    User User `gorm:"foreignKey:UserID;references:ID;"`
    RoleID uuid.UUID `gorm:"validate:required"` 
    Role Role `gorm:"foreignKey:RoleID;references:ID;"`
}

func (ru *RoleUser) BeforeCreate(tx *gorm.DB) (err error) {
	ru.ID = uuid.New()
	return nil
}