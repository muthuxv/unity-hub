package models

import (
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type ChannelChannelPermissions struct {
	ID                  uuid.UUID `gorm:"type:uuid;primaryKey"`
	gorm.Model
	ChannelID           uuid.UUID `gorm:"type:uuid;not null"`
	ChannelPermissionID uuid.UUID `gorm:"type:uuid;not null"`
	Power               int       `gorm:"validate:required"`
}

func (ccp *ChannelChannelPermissions) BeforeCreate(tx *gorm.DB) (err error) {
	ccp.ID = uuid.New()
	return nil
}
