package models

import (
    "gorm.io/gorm"
)

type React struct {
    gorm.Model
    ID   uint   `gorm:"primaryKey"`
    Name string `gorm:"validate:required"`
}
