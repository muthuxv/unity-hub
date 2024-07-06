package models

import (
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type ActiveRule struct {
	ID uuid.UUID `gorm:"type:uuid;primaryKey"`
	gorm.Model
	Status         bool   `gorm:"not null"`
	UserID         uuid.UUID   `gorm:"not null"`
	User           User   `gorm:"foreignKey:UserID;references:ID;constraint:OnUpdate:CASCADE,OnDelete:SET NULL;"`
	RuleID uuid.UUID   `gorm:"not null"`
	Rule   Rule   `gorm:"foreignKey:RuleID;references:ID;constraint:OnUpdate:CASCADE,OnDelete:SET NULL;"`  
}

func (ar *ActiveRule) BeforeCreate(tx *gorm.DB) (err error) {
	ar.ID = uuid.New()
	return nil
}