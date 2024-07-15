package tests

import (
	"app/db/models"
	"app/testutils"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"gorm.io/gorm"
	"testing"
)

func TestCreateFriend(t *testing.T) {
	db := testutils.SetupTestDB()

	// Prérequis : Créer deux utilisateurs
	user1 := models.User{
		Pseudo:   "user1",
		Email:    "user1@example.com",
		Password: "password123",
	}
	user2 := models.User{
		Pseudo:   "user2",
		Email:    "user2@example.com",
		Password: "password123",
	}

	err := db.Create(&user1).Error
	assert.Nil(t, err)
	err = db.Create(&user2).Error
	assert.Nil(t, err)

	friend := models.Friend{
		Status:  "pending",
		UserID1: user1.ID,
		UserID2: user2.ID,
	}

	err = db.Create(&friend).Error
	assert.Nil(t, err)
	assert.NotEqual(t, uuid.Nil, friend.ID)
}

func TestReadFriend(t *testing.T) {
	db := testutils.SetupTestDB()

	// Prérequis : Créer deux utilisateurs
	user1 := models.User{
		Pseudo:   "user1",
		Email:    "user1@example.com",
		Password: "password123",
	}
	user2 := models.User{
		Pseudo:   "user2",
		Email:    "user2@example.com",
		Password: "password123",
	}

	err := db.Create(&user1).Error
	assert.Nil(t, err)
	err = db.Create(&user2).Error
	assert.Nil(t, err)

	friend := models.Friend{
		Status:  "pending",
		UserID1: user1.ID,
		UserID2: user2.ID,
	}

	err = db.Create(&friend).Error
	assert.Nil(t, err)

	var fetchedFriend models.Friend
	err = db.Preload("User1").Preload("User2").First(&fetchedFriend, "id = ?", friend.ID).Error
	assert.Nil(t, err)
	assert.Equal(t, friend.ID, fetchedFriend.ID)
	assert.Equal(t, friend.Status, fetchedFriend.Status)
	assert.Equal(t, user1.ID, fetchedFriend.UserID1)
	assert.Equal(t, user2.ID, fetchedFriend.UserID2)
}

func TestUpdateFriend(t *testing.T) {
	db := testutils.SetupTestDB()

	// Prérequis : Créer deux utilisateurs
	user1 := models.User{
		Pseudo:   "user1",
		Email:    "user1@example.com",
		Password: "password123",
	}
	user2 := models.User{
		Pseudo:   "user2",
		Email:    "user2@example.com",
		Password: "password123",
	}

	err := db.Create(&user1).Error
	assert.Nil(t, err)
	err = db.Create(&user2).Error
	assert.Nil(t, err)

	friend := models.Friend{
		Status:  "pending",
		UserID1: user1.ID,
		UserID2: user2.ID,
	}

	err = db.Create(&friend).Error
	assert.Nil(t, err)

	friend.Status = "accepted"
	err = db.Save(&friend).Error
	assert.Nil(t, err)

	var updatedFriend models.Friend
	err = db.First(&updatedFriend, "id = ?", friend.ID).Error
	assert.Nil(t, err)
	assert.Equal(t, "accepted", updatedFriend.Status)
}

func TestDeleteFriend(t *testing.T) {
	db := testutils.SetupTestDB()

	// Prérequis : Créer deux utilisateurs
	user1 := models.User{
		Pseudo:   "user1",
		Email:    "user1@example.com",
		Password: "password123",
	}
	user2 := models.User{
		Pseudo:   "user2",
		Email:    "user2@example.com",
		Password: "password123",
	}

	err := db.Create(&user1).Error
	assert.Nil(t, err)
	err = db.Create(&user2).Error
	assert.Nil(t, err)

	friend := models.Friend{
		Status:  "pending",
		UserID1: user1.ID,
		UserID2: user2.ID,
	}

	err = db.Create(&friend).Error
	assert.Nil(t, err)

	err = db.Delete(&friend).Error
	assert.Nil(t, err)

	var deletedFriend models.Friend
	err = db.First(&deletedFriend, "id = ?", friend.ID).Error
	assert.NotNil(t, err)
	assert.Equal(t, gorm.ErrRecordNotFound, err)
}
