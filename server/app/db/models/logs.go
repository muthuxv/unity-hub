package models

import (
    "gorm.io/gorm"
)

type Logs struct {
    gorm.Model
    ID       uint   `gorm:"primaryKey"`
    Message  string `gorm:"validate:required"`
    ServerID uint   `gorm:"validate:required"`
    Server Server `gorm:"foreignKey:ServerID;references:ID;"`
}
