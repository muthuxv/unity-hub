package models

import (
    "gorm.io/gorm"
)

type EventServer struct {
    gorm.Model
    ID       uint `gorm:"primaryKey"`
    ServerID uint `gorm:"validate:required"`
    Server Server `gorm:"foreignKey:ServerID;references:ID;"`
    EventID  uint `gorm:"validate:required"`
    Event  Event  `gorm:"foreignKey:EventID;references:ID;"`
}
