package models

import (
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type GroupMember struct {
	ID uuid.UUID `gorm:"type:uuid;primaryKey"`
	gorm.Model
	UserID  uuid.UUID `gorm:"not null"`
	User    User      `gorm:"foreignKey:UserID;references:ID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE"`
	GroupID uuid.UUID `gorm:"not null"`
	Group   Group     `gorm:"foreignKey:GroupID;references:ID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE"`
}

func (gm *GroupMember) BeforeCreate(tx *gorm.DB) (err error) {
	gm.ID = uuid.New()
	return nil
}
