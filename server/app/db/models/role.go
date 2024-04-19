package models

import (
    "gorm.io/gorm"
)

type Role struct {
    gorm.Model
    ID       uint   `gorm:"primaryKey"`
    Label    string `gorm:"validate:required"`
    ServerID uint   `gorm:"validate:required"`
    Server Server `gorm:"foreignKey:ServerID;references:ID;"`
}
