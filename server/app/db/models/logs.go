package models

import (
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Logs struct {
	ID uuid.UUID `gorm:"type:uuid;primaryKey"`
	gorm.Model
	Message  string    `gorm:"validate:required"`
	ServerID uuid.UUID `gorm:"validate:required"`
	Server   Server    `gorm:"foreignKey:ServerID;references:ID;"`
}

type LogsSwagger struct {
	ID       uuid.UUID     `json:"id"`
	Message  string        `json:"message"`
	ServerID uuid.UUID     `json:"server_id"`
	Server   ServerSwagger `json:"server"`
}

func (l *Logs) BeforeCreate(tx *gorm.DB) (err error) {
	l.ID = uuid.New()
	return nil
}
