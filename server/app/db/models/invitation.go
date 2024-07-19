package models

import (
	"github.com/google/uuid"
	"gorm.io/gorm"
	"time"
)

type Invitation struct {
	ID uuid.UUID `gorm:"type:uuid;primaryKey"`
	gorm.Model
	Link           string
	IsAccepted     bool      `gorm:"default:false"`
	Expire         time.Time `gorm:"validate:required"`
	UserSenderID   uuid.UUID `gorm:"validate:required"`
	UserSender     User      `gorm:"foreignKey:UserSenderID;references:ID;"`
	UserReceiverID uuid.UUID `gorm:"validate:required"`
	UserReceiver   User      `gorm:"foreignKey:UserReceiverID;references:ID;"`
	ServerID       uuid.UUID `gorm:"validate:required"`
	Server         Server    `gorm:"foreignKey:ServerID;references:ID;"`
}

func (i *Invitation) BeforeCreate(tx *gorm.DB) (err error) {
	i.ID = uuid.New()
	return nil
}
