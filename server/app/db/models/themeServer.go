package models

import (
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type ThemeServer struct {
	ID uuid.UUID `gorm:"type:uuid;primaryKey"`
	gorm.Model
	ServerID uuid.UUID `gorm:"validate:required"`
	Server   Server    `gorm:"foreignKey:ServerID;references:ID;"`
	ThemeID  uuid.UUID `gorm:"validate:required"`
	Theme    Theme     `gorm:"foreignKey:ThemeID;references:ID;"`
}
