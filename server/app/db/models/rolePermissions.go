package models

import (
    "gorm.io/gorm"
)

type RolePermissions struct {
    gorm.Model
    ID            uint `gorm:"primaryKey"`
    Power         int  `gorm:"validate:required"`
    RoleID        uint `gorm:"validate:required"`
    Role        Role        `gorm:"foreignKey:RoleID;references:ID;"`
    PermissionsID uint `gorm:"validate:required"`
    Permissions Permissions `gorm:"foreignKey:PermissionsID;references:ID;"`
}
