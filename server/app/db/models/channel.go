package models

import (
    "gorm.io/gorm"
)

type Channel struct {
    gorm.Model
    ID         uint   `gorm:"primaryKey"`
    Name       string `gorm:"validate:required"`
    Type       string `gorm:"validate:required"`
    Permission string `gorm:"validate:required"` 
}
