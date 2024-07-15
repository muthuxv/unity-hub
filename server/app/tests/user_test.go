package tests

import (
	"app/db/models"
	"app/testutils"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"gorm.io/gorm"
	"testing"
)

func TestCreateUser(t *testing.T) {
	db := testutils.SetupTestDB()

	user := models.User{
		Pseudo:   "testuser",
		Email:    "testuser@example.com",
		Password: "password123",
	}

	err := db.Create(&user).Error
	assert.Nil(t, err)
	assert.NotEqual(t, uuid.Nil, user.ID)
}

func TestReadUser(t *testing.T) {
	db := testutils.SetupTestDB()

	user := models.User{
		Pseudo:   "testuser",
		Email:    "testuser@example.com",
		Password: "password123",
	}

	err := db.Create(&user).Error
	assert.Nil(t, err)

	var fetchedUser models.User
	err = db.First(&fetchedUser, "id = ?", user.ID).Error
	assert.Nil(t, err)
	assert.Equal(t, user.ID, fetchedUser.ID)
	assert.Equal(t, user.Pseudo, fetchedUser.Pseudo)
	assert.Equal(t, user.Email, fetchedUser.Email)
}

func TestUpdateUser(t *testing.T) {
	db := testutils.SetupTestDB()

	user := models.User{
		Pseudo:   "testuser",
		Email:    "testuser@example.com",
		Password: "password123",
	}

	err := db.Create(&user).Error
	assert.Nil(t, err)

	user.Pseudo = "updateduser"
	err = db.Save(&user).Error
	assert.Nil(t, err)

	var updatedUser models.User
	err = db.First(&updatedUser, "id = ?", user.ID).Error
	assert.Nil(t, err)
	assert.Equal(t, "updateduser", updatedUser.Pseudo)
}

func TestDeleteUser(t *testing.T) {
	db := testutils.SetupTestDB()

	user := models.User{
		Pseudo:   "testuser",
		Email:    "testuser@example.com",
		Password: "password123",
	}

	err := db.Create(&user).Error
	assert.Nil(t, err)

	err = db.Delete(&user).Error
	assert.Nil(t, err)

	var deletedUser models.User
	err = db.First(&deletedUser, "id = ?", user.ID).Error
	assert.NotNil(t, err)
	assert.Equal(t, gorm.ErrRecordNotFound, err)
}
