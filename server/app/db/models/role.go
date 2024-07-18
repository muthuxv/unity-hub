package models

import (
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Role struct {
	ID uuid.UUID `gorm:"type:uuid;primaryKey"`
	gorm.Model
	Label    string    `gorm:"validate:required"`
	ServerID uuid.UUID `gorm:"validate:required"`
	Server   Server    `gorm:"foreignKey:ServerID;references:ID;"`
}

func (r *Role) BeforeCreate(tx *gorm.DB) (err error) {
	r.ID = uuid.New()
	return nil
}

func (r *Role) AfterCreate(tx *gorm.DB) (err error) {
	var permissions []Permissions
	if err := tx.Find(&permissions).Error; err != nil {
		return err
	}

	for _, perm := range permissions {
		var power int

		if r.Label == "admin" {
			if perm.Label == "editChannel" || perm.Label == "accessChannel" || perm.Label == "sendMessage" {
				power = 99
			} else {
				power = 1
			}
		} else {
			power = 0
		}

		rolePerm := RolePermissions{
			RoleID:        r.ID,
			PermissionsID: perm.ID,
			Power:         power,
		}

		if err := tx.Create(&rolePerm).Error; err != nil {
			return err
		}
	}

	return nil
}
