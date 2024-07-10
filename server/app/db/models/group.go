package models

import (
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Group struct {
	ID uuid.UUID `gorm:"type:uuid;primaryKey"`
	gorm.Model
	Type      string    `gorm:"validate:required"`
	ChannelID uuid.UUID `gorm:"not null"`
	Channel   *Channel  `gorm:"foreignKey:ChannelID;references:ID;constraint:OnUpdate:CASCADE,OnDelete:SET NULL"`
	Members   []User    `gorm:"many2many:group_members;constraint:OnUpdate:CASCADE,OnDelete:SET NULL"`
}

func (g *Group) BeforeCreate(tx *gorm.DB) (err error) {
	g.ID = uuid.New()
	return nil
}
