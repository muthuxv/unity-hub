package models

import (
    "gorm.io/gorm"
)

type Permissions struct {
    gorm.Model
    ID    uint   `gorm:"primaryKey"`
    Label string `gorm:"validate:required"`
}
