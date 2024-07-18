package models

import (
	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Friend represents a friend relationship between two users.
type Friend struct {
	ID uuid.UUID `gorm:"type:uuid;primaryKey"`
	gorm.Model
	Status  string    `gorm:"validate:required"`
	UserID1 uuid.UUID `gorm:"validate:required"`
	User1   User      `gorm:"foreignKey:UserID1;references:ID;"`
	UserID2 uuid.UUID `gorm:"validate:required"`
	User2   User      `gorm:"foreignKey:UserID2;references:ID;"`
}

// BeforeCreate sets the ID to a new UUID before creating a friend record.
func (f *Friend) BeforeCreate(tx *gorm.DB) (err error) {
	f.ID = uuid.New()
	return nil
}

// ErrorResponse represents an error response.
type ErrorResponse struct {
	Error string `json:"error"`
}

// FriendRequest represents a friend request payload.
type FriendRequest struct {
	ID      uuid.UUID `json:"id"`      // ID of the friend request
	UserID2 uuid.UUID `json:"userId2"` // ID of the user who is supposed to accept/refuse the friend request
}

// FriendResponse represents a response containing friend data.
type FriendResponse struct {
	ID         uuid.UUID `json:"id"`
	FriendID   uuid.UUID `json:"friendId"`
	Status     string    `json:"status"`
	UserPseudo string    `json:"userPseudo"`
	UserMail   string    `json:"userMail"`
	Profile    string    `json:"profile"`
}

// SearchUserResponse represents a user found by search.
type SearchUserResponse struct {
	ID      uuid.UUID `json:"id"`
	Pseudo  string    `json:"pseudo"`
	Email   string    `json:"email"`
	Profile string    `json:"profile"`
}
