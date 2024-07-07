package models

import (
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Message struct {
	ID uuid.UUID `gorm:"type:uuid;primaryKey"`
	gorm.Model
	Content   string  `gorm:"validate:required"`
	Type      string  `gorm:"validate:required"`
	SentAt    string  `gorm:"validate:required"`
	UserID    uuid.UUID    `gorm:"validate:required"`
	User      User    `gorm:"foreignKey:UserID;references:ID;"`
	ChannelID uuid.UUID    `gorm:"validate:required"`
	Channel   Channel `gorm:"foreignKey:ChannelID;references:ID;"`
}

func (m *Message) BeforeCreate(tx *gorm.DB) (err error) {
	m.ID = uuid.New()
	return nil
}