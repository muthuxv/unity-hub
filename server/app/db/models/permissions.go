package models

import (
	"github.com/google/uuid"
    "gorm.io/gorm"
)

type Permissions struct {
	ID    uuid.UUID `gorm:"type:uuid;primaryKey"`
    gorm.Model
    Label string `gorm:"validate:required"`
}

func (p *Permissions) BeforeCreate(tx *gorm.DB) (err error) {
	p.ID = uuid.New()
	return nil
}

func CreateInitialPermissions(db *gorm.DB) {
	initialPermissions := []Permissions{
		{Label: "createChannel"},
		{Label: "sendMessage"},
		{Label: "accessChannel"},
		{Label: "banUser"},
		{Label: "kickUser"},
		{Label: "createRole"},
		{Label: "accessLog"},
		{Label: "accessReport"},
		{Label: "profileServer"},
		{Label: "editChannel"},
	}

	for _, perm := range initialPermissions {
		var existing Permissions
		if err := db.Where("label = ?", perm.Label).First(&existing).Error; err != nil {
			if err == gorm.ErrRecordNotFound {
				db.Create(&perm)
			}
		}
	}
}
