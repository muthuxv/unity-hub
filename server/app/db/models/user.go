package models

import (
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

type User struct {
	ID uuid.UUID `gorm:"type:uuid;primaryKey"`
	gorm.Model
	Pseudo            string `gorm:"unique;validate:required"`
	Email             string `gorm:"unique;validate:required,email"`
	Role              string `gorm:"default:user"`
	Password          string `gorm:"validate:required,min=5,containsany=0123456789"`
	VerificationToken string `gorm:"size:255"`
	IsVerified        bool   `gorm:"default:false"`
	Provider          string
	ProviderID        string
	Profile           string `gorm:"default:default.jpg"`
	FcmToken          string `gorm:"size:255"`
}

func (u *User) BeforeCreate(tx *gorm.DB) (err error) {
	u.ID = uuid.New()
	return nil
}

func (u *User) BeforeSave(tx *gorm.DB) (err error) {
	if len(u.Password) > 0 {
		hashedPassword, err := bcrypt.GenerateFromPassword([]byte(u.Password), 14)
		if err != nil {
			return err
		}
		u.Password = string(hashedPassword)
	}
	return nil
}
