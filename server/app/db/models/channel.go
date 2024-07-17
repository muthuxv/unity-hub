package models

import (
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Channel struct {
	ID       uuid.UUID `gorm:"type:uuid;primaryKey"`
	gorm.Model
	Name     string    `gorm:"validate:required"`
	Type     string    `gorm:"validate:required"`
	ServerID uuid.UUID `gorm:"validate:required"`
}

func (c *Channel) BeforeCreate(tx *gorm.DB) (err error) {
	c.ID = uuid.New()
	return nil
}

func (c *Channel) AfterCreate(tx *gorm.DB) (err error) {
	var permissions []ChannelPermissions
	if err := tx.Find(&permissions).Error; err != nil {
		return err
	}

	for _, perm := range permissions {
		power := 0
		if perm.Label == "editChannel" {
			power = 1
		}

		link := ChannelChannelPermissions{
			ChannelID:           c.ID,
			ChannelPermissionID: perm.ID,
			Power:               power,
		}

		if err := tx.Create(&link).Error; err != nil {
			return err
		}
	}

	return nil
}