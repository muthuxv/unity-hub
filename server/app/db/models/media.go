package models

import (
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type MediaSwagger struct {
	ID       uuid.UUID `json:"id"`
	FileName string    `json:"file_name"`
	MimeType string    `json:"mime_type"`
	UserID   uuid.UUID `json:"user_id"`
}

type Media struct {
	ID uuid.UUID `gorm:"type:uuid;primaryKey"`
	gorm.Model
	FileName string
	MimeType string
	UserID   uuid.UUID `gorm:"constraint:OnUpdate:CASCADE,OnDelete:SET NULL;"`
	User     *User     `gorm:"foreignKey:UserID"`
}

func (m *Media) BeforeCreate(tx *gorm.DB) (err error) {
	m.ID = uuid.New()
	return nil
}
