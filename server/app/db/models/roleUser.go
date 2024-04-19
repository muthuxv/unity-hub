package models

import (
    "gorm.io/gorm"
)

type RoleUser struct {
    gorm.Model
    ID     uint `gorm:"primaryKey"`
    UserID uint `gorm:"validate:required"` 
    User User `gorm:"foreignKey:UserID;references:ID;"`
    RoleID uint `gorm:"validate:required"` 
    Role Role `gorm:"foreignKey:RoleID;references:ID;"`
}
