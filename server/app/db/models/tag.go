package models

import (
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Tag struct {
	ID uuid.UUID `gorm:"type:uuid;primaryKey"`
	gorm.Model
	Name string `gorm:"unique;validate:required"`
}

type TagSwagger struct {
	ID   uuid.UUID `json:"id"`
	Name string    `json:"name"`
}
