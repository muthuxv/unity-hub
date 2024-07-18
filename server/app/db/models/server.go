package models

import (
	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Server represents a server.
type Server struct {
	ID uuid.UUID `gorm:"type:uuid;primaryKey"`
	gorm.Model
	Name       string    `gorm:"validate:required"`
	Visibility string    `gorm:"validate:required"`
	MediaID    uuid.UUID `gorm:"validate:required"`
	Media      Media     `gorm:"foreignKey:MediaID;references:ID;"`
	Tags       []Tag     `gorm:"many2many:server_tags;"`
	UserID     uuid.UUID `gorm:"not null"`
	User       User      `gorm:"foreignKey:UserID;references:ID;constraint:OnUpdate:CASCADE,OnDelete:SET NULL"`
}

type ServerSwagger struct {
	ID         uuid.UUID    `json:"id"`
	Name       string       `json:"name"`
	Visibility string       `json:"visibility"`
	MediaID    uuid.UUID    `json:"media_id"`
	UserID     uuid.UUID    `json:"user_id"`
	Media      MediaSwagger `json:"media"`
	Tags       []TagSwagger `json:"tags"`
}

// ErrorServerResponse represents an error response.
type ErrorServerResponse struct {
	Error string `json:"error"`
}

// SuccessServerResponse represents a success response.
type SuccessServerResponse struct {
	Message string `json:"message"`
}
