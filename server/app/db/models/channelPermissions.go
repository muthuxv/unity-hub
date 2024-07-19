package models

import (
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type ChannelPermissions struct {
	ID    uuid.UUID `gorm:"type:uuid;primaryKey"`
	gorm.Model
	Label string `gorm:"validate:required"`
}

func (cp *ChannelPermissions) BeforeCreate(tx *gorm.DB) (err error) {
	cp.ID = uuid.New()
	return nil
}

func CreateInitialChannelPermissions(db *gorm.DB) {
	initialPermissions := []ChannelPermissions{
		{Label: "sendMessage"},
		{Label: "accessChannel"},
		{Label: "editChannel"},
	}

	for _, perm := range initialPermissions {
		var existing ChannelPermissions
		if err := db.Where("label = ?", perm.Label).First(&existing).Error; err != nil {
			if err == gorm.ErrRecordNotFound {
				db.Create(&perm)
			}
		}
	}
}