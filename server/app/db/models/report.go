package models

import (
    "gorm.io/gorm"
)

type Report struct {
    gorm.Model
    ID        uint   `gorm:"primaryKey"`
    Message   string `gorm:"validate:required"`
    Status    string `gorm:"validate:required"`
    MessageID uint   `gorm:"validate:required"` 
    ReportedMessage Message `gorm:"foreignKey:MessageID;references:ID;"`
}
