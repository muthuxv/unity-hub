package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Ban struct {
	ID uuid.UUID `gorm:"type:uuid;primaryKey"`
	gorm.Model
	Reason     string    `gorm:"validate:required"`
	Duration   time.Time `gorm:"validate:required"`
	UserID     uuid.UUID `gorm:"not null"`
	User       User      `gorm:"foreignKey:UserID;references:ID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE"`
	ServerID   uuid.UUID `gorm:"not null"`
	Server     Server    `gorm:"foreignKey:ServerID;references:ID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE"`
	BannedByID uuid.UUID `gorm:"not null"`
	BannedBy   User      `gorm:"foreignKey:BannedByID;references:ID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE"`
}

type BanSwagger struct {
	ID         uuid.UUID     `json:"id"`
	Reason     string        `json:"reason"`
	Duration   time.Time     `json:"duration"`
	UserID     uuid.UUID     `json:"user_id"`
	User       UserSwagger   `json:"user"`
	ServerID   uuid.UUID     `json:"server_id"`
	Server     ServerSwagger `json:"server"`
	BannedByID uuid.UUID     `json:"banned_by_id"`
	BannedBy   UserSwagger   `json:"banned_by"`
}

func (b *Ban) BeforeCreate(tx *gorm.DB) (err error) {
	b.ID = uuid.New()
	return
}
