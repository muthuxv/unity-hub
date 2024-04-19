package models

import (
    "gorm.io/gorm"
)

type ThemeServer struct {
    gorm.Model
    ID       uint `gorm:"primaryKey"`
    ServerID uint `gorm:"validate:required"`
    Server Server `gorm:"foreignKey:ServerID;references:ID;"`
    ThemeID  uint `gorm:"validate:required"`
    Theme  Theme  `gorm:"foreignKey:ThemeID;references:ID;"`
}
