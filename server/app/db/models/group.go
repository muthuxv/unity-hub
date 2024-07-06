package models

import (
	"gorm.io/gorm"
	"github.com/google/uuid"
)

type Group struct {
	ID uuid.UUID `gorm:"type:uuid;primaryKey"`
	gorm.Model
	Type      string   `gorm:"validate:required"`
	ChannelID uuid.UUID     `gorm:"not null"`
	Channel   *Channel `gorm:"foreignKey:ChannelID;references:ID;constraint:OnUpdate:CASCADE,OnDelete:SET NULL"`
}

func (g *Group) BeforeCreate(tx *gorm.DB) (err error) {
	g.ID = uuid.New()
	return nil
}