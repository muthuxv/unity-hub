package models

import (
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type OnServer struct {
	ID uuid.UUID `gorm:"type:uuid;primaryKey"`
	gorm.Model
	UserID   uuid.UUID `gorm:"validate:required"`
	User     User      `gorm:"foreignKey:UserID;references:ID;"`
	ServerID uuid.UUID `gorm:"validate:required"`
	Server   Server    `gorm:"foreignKey:ServerID;references:ID;"`
}

type OnServerSwagger struct {
	ID       uuid.UUID     `json:"id"`
	UserID   uuid.UUID     `json:"user_id"`
	User     UserSwagger   `json:"user"`
	ServerID uuid.UUID     `json:"server_id"`
	Server   ServerSwagger `json:"server"`
}

func (os *OnServer) BeforeCreate(tx *gorm.DB) (err error) {
	os.ID = uuid.New()
	return nil
}
