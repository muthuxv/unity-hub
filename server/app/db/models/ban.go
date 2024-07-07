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

func (b *Ban) BeforeCreate(tx *gorm.DB) (err error) {
	b.ID = uuid.New()
	return
}
