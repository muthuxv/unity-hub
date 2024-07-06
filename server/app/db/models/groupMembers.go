package models

import (
	"gorm.io/gorm"
	"github.com/google/uuid"
)

type GroupMember struct {
	ID uuid.UUID `gorm:"type:uuid;primaryKey"`
	gorm.Model
	User    User  `gorm:"foreignKey:UserID;references:ID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE"`
	GroupID uint  `gorm:"not null"`
	Group   Group `gorm:"foreignKey:GroupID;references:ID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE"`
}

func (gm *GroupMember) BeforeCreate(tx *gorm.DB) (err error) {
	gm.ID = uuid.New()
	return nil
}