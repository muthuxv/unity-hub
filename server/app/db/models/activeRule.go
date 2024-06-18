package models

import (
	"gorm.io/gorm"
)

type ActiveRule struct {
	gorm.Model
	Status         bool   `gorm:"not null"`
	UserID         uint   `gorm:"not null"`
	User           User   `gorm:"foreignKey:UserID;references:ID;constraint:OnUpdate:CASCADE,OnDelete:SET NULL;"`
	RuleID uint   `gorm:"not null"`
	Rule   Rule   `gorm:"foreignKey:RuleID;references:ID;constraint:OnUpdate:CASCADE,OnDelete:SET NULL;"`  
}