package models

import (
    "gorm.io/gorm"
)

type Friend struct {
    gorm.Model
    ID      uint   `gorm:"primaryKey"`
    Status  string `gorm:"validate:required"`
    UserID1 uint   `gorm:"validate:required"` 
    User1 User `gorm:"foreignKey:UserID1;references:ID;"`
    UserID2 uint   `gorm:"validate:required"`
    User2 User `gorm:"foreignKey:UserID2;references:ID;"`
}
