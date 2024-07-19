package models

import (
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Feature struct {
	gorm.Model
	ID     uuid.UUID `gorm:"type:uuid;primaryKey"`
	Name   string    `gorm:"unique;validate:required"`
	Status string    `gorm:"validate:required"`
}

func (f *Feature) BeforeCreate(tx *gorm.DB) (err error) {
	f.ID = uuid.New()
	return nil
}

func CreateInitialFeatures(db *gorm.DB) {
	initialFeatures := []Feature{
		{Name: "Serveurs", Status: "true"},
		{Name: "Notifications", Status: "true"},
		{Name: "Profil", Status: "true"},
		{Name: "Messages", Status: "true"},
	}

	for _, perm := range initialFeatures {
		var existing Feature
		if err := db.Where("name = ? AND status = ?", perm.Name, perm.Status).First(&existing).Error; err != nil {
			if err == gorm.ErrRecordNotFound {
				db.Create(&perm)
			}
		}
	}
}
