package models

import (
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Role struct {
	ID       uuid.UUID `gorm:"type:uuid;primaryKey"`
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

	power := 0
	if r.Label == "admin" {
		power = 1
	}

	for _, perm := range permissions {
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