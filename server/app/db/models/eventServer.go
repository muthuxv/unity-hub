package models

import (
    "gorm.io/gorm"
	"github.com/google/uuid"
)

type EventServer struct {
    ID uuid.UUID `gorm:"type:uuid;primaryKey"`
    gorm.Model
    ServerID uuid.UUID `gorm:"validate:required"`
    Server Server `gorm:"foreignKey:ServerID;references:ID;"`
    EventID  uuid.UUID `gorm:"validate:required"`
    Event  Event  `gorm:"foreignKey:EventID;references:ID;"`
}

func (es *EventServer) BeforeCreate(tx *gorm.DB) (err error) {
	es.ID = uuid.New()
	return nil
}