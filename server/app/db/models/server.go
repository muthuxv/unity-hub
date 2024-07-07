package models

import (
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Server struct {
	ID uuid.UUID `gorm:"type:uuid;primaryKey"`
	gorm.Model
	Name       string `gorm:"validate:required"`
	Visibility string `gorm:"validate:required"`
	MediaID    uuid.UUID   `gorm:"validate:required"`
	Media      Media  `gorm:"foreignKey:MediaID;references:ID;"`
	Tags       []Tag  `gorm:"many2many:server_tags;"`
	UserID     uuid.UUID   `gorm:"not null"`
	User       User   `gorm:"foreignKey:UserID;references:ID;constraint:OnUpdate:CASCADE,OnDelete:SET NULL"`
}

func (s *Server) BeforeCreate(tx *gorm.DB) (err error) {
	s.ID = uuid.New()
	return nil
}