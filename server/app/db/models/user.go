package models

import (
    "golang.org/x/crypto/bcrypt"
    "gorm.io/gorm"
)

type User struct {
    gorm.Model
    Email             string `gorm:"unique" validate:"required,email"`
    Role              string `gorm:"default:user"`
    Password          string `validate:"required,min=5,containsany=0123456789"`
    VerificationToken string `gorm:"size:255"`
    IsVerified        bool   `gorm:"default:false"`
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
