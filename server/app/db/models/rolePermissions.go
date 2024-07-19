package models

import (
	"github.com/google/uuid"
    "gorm.io/gorm"
)

type RolePermissions struct {
	ID uuid.UUID `gorm:"type:uuid;primaryKey"`
    gorm.Model
    Power         int  `gorm:"validate:required"`
    RoleID        uuid.UUID `gorm:"validate:required"`
    Role        Role        `gorm:"foreignKey:RoleID;references:ID;"`
    PermissionsID uuid.UUID `gorm:"validate:required"`
    Permissions Permissions `gorm:"foreignKey:PermissionsID;references:ID;"`
}

func (rp *RolePermissions) BeforeCreate(tx *gorm.DB) (err error) {
	rp.ID = uuid.New()
	return nil
}