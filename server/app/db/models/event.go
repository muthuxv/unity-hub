package models

import (
    "gorm.io/gorm"
    "time"
)

type Event struct {
    gorm.Model
    ID   uint      `gorm:"primaryKey"`
    Name string    `gorm:"validate:required"`
    Description string    `gorm:""`
    Date time.Time `gorm:"validate:required"`
}
