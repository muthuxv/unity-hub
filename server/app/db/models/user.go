package models

import (
	"strings"
	"time"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

// User represents a user in the system.
type User struct {
	ID                uuid.UUID `gorm:"type:uuid;primaryKey"`
	Pseudo            string    `gorm:"unique;validate:required"`
	Email             string    `gorm:"unique;validate:required,email"`
	Role              string    `gorm:"default:user"`
	Password          string    `gorm:"validate:required,min=5,containsany=0123456789"`
	VerificationToken string    `gorm:"size:255"`
	IsVerified        bool      `gorm:"default:false"`
	Provider          string
	ProviderID        string
	Profile           string    `gorm:"default:default.jpg"`
	FcmToken          string    `gorm:"size:255"`
	CreatedAt         time.Time `json:"created_at"`
	UpdatedAt         time.Time `json:"updated_at"`
}

func (u *User) BeforeCreate(tx *gorm.DB) (err error) {
	u.ID = uuid.New()
	return nil
}

func (u *User) BeforeSave(tx *gorm.DB) (err error) {
	u.Email = strings.ToLower(u.Email)
	if len(u.Password) > 0 {
		hashedPassword, err := bcrypt.GenerateFromPassword([]byte(u.Password), 14)
		if err != nil {
			return err
		}
		u.Password = string(hashedPassword)
	}
	return nil
}

// UserSwagger represents the user model for Swagger documentation.
type UserSwagger struct {
	ID                uuid.UUID `json:"id"`
	Pseudo            string    `json:"pseudo"`
	Email             string    `json:"email"`
	Role              string    `json:"role"`
	VerificationToken string    `json:"verification_token"`
	IsVerified        bool      `json:"is_verified"`
	Provider          string    `json:"provider"`
	ProviderID        string    `json:"provider_id"`
	Profile           string    `json:"profile"`
	FcmToken          string    `json:"fcm_token"`
	CreatedAt         time.Time `json:"created_at"`
	UpdatedAt         time.Time `json:"updated_at"`
}

// SuccessResponse represents a successful response.
type SuccessResponse struct {
	Message string `json:"message"`
}

// ErrorUserResponse represents an error response.
type ErrorUserResponse struct {
	Error string `json:"error"`
}

// LoginPayload represents the payload for login.
type LoginPayload struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

// ChangePasswordPayload represents the payload for changing password.
type ChangePasswordPayload struct {
	CurrentPassword string `json:"currentPassword" binding:"required"`
	NewPassword     string `json:"newPassword" binding:"required,min=6"`
}

// UpdateUserDataPayload represents the payload for updating user data.
type UpdateUserDataPayload struct {
	Pseudo  string `json:"pseudo"`
	Profile string `json:"profile"`
}

// TokenResponse represents the response containing a JWT token.
type TokenResponse struct {
	Token string `json:"token"`
}

// FcmTokenPayload represents the payload for registering FCM token.
type FcmTokenPayload struct {
	FcmToken string `json:"fcmToken" binding:"required"`
}

type UserResponse struct {
	ID      uuid.UUID `json:"ID"`
	Pseudo  string    `json:"Pseudo"`
	Profile string    `json:"Profile"`
}
