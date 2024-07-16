package tests

import (
	"app/db/models"
	"app/testutils"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"gorm.io/gorm"
	"testing"
)

func TestCreateServer(t *testing.T) {
	db := testutils.SetupTestDB()

	// Prérequis : Créer un utilisateur et un média
	user := models.User{
		Pseudo:   "user1",
		Email:    "user1@example.com",
		Password: "password123",
	}

	err := db.Create(&user).Error
	assert.Nil(t, err)

	media := models.Media{
		FileName: "testfile",
		MimeType: "image/png",
		UserID:   user.ID, // Utilisez l'ID de l'utilisateur créé
	}

	err = db.Create(&media).Error
	assert.Nil(t, err)

	server := models.Server{
		Name:       "Test Server",
		Visibility: "public",
		MediaID:    media.ID, // Utilisez l'ID du média créé
		UserID:     user.ID,  // Utilisez l'ID de l'utilisateur créé
	}

	err = db.Create(&server).Error
	assert.Nil(t, err)
	assert.NotEqual(t, uuid.Nil, server.ID)
}

func TestReadServer(t *testing.T) {
	db := testutils.SetupTestDB()

	// Prérequis : Créer un utilisateur et un média
	user := models.User{
		Pseudo:   "user1",
		Email:    "user1@example.com",
		Password: "password123",
	}

	err := db.Create(&user).Error
	assert.Nil(t, err)

	media := models.Media{
		FileName: "testfile",
		MimeType: "image/png",
		UserID:   user.ID, // Utilisez l'ID de l'utilisateur créé
	}

	err = db.Create(&media).Error
	assert.Nil(t, err)

	server := models.Server{
		Name:       "Test Server",
		Visibility: "public",
		MediaID:    media.ID, // Utilisez l'ID du média créé
		UserID:     user.ID,  // Utilisez l'ID de l'utilisateur créé
	}

	err = db.Create(&server).Error
	assert.Nil(t, err)

	var fetchedServer models.Server
	err = db.Preload("Media").Preload("User").First(&fetchedServer, "id = ?", server.ID).Error
	assert.Nil(t, err)
	assert.Equal(t, server.ID, fetchedServer.ID)
	assert.Equal(t, server.Name, fetchedServer.Name)
	assert.Equal(t, server.Visibility, fetchedServer.Visibility)
	assert.Equal(t, media.ID, fetchedServer.MediaID)
	assert.Equal(t, user.ID, fetchedServer.UserID)
}

func TestUpdateServer(t *testing.T) {
	db := testutils.SetupTestDB()

	// Prérequis : Créer un utilisateur et un média
	user := models.User{
		Pseudo:   "user1",
		Email:    "user1@example.com",
		Password: "password123",
	}

	err := db.Create(&user).Error
	assert.Nil(t, err)

	media := models.Media{
		FileName: "testfile",
		MimeType: "image/png",
		UserID:   user.ID, // Utilisez l'ID de l'utilisateur créé
	}

	err = db.Create(&media).Error
	assert.Nil(t, err)

	server := models.Server{
		Name:       "Test Server",
		Visibility: "public",
		MediaID:    media.ID, // Utilisez l'ID du média créé
		UserID:     user.ID,  // Utilisez l'ID de l'utilisateur créé
	}

	err = db.Create(&server).Error
	assert.Nil(t, err)

	server.Name = "Updated Server"
	err = db.Save(&server).Error
	assert.Nil(t, err)

	var updatedServer models.Server
	err = db.First(&updatedServer, "id = ?", server.ID).Error
	assert.Nil(t, err)
	assert.Equal(t, "Updated Server", updatedServer.Name)
}

func TestDeleteServer(t *testing.T) {
	db := testutils.SetupTestDB()

	// Prérequis : Créer un utilisateur et un média
	user := models.User{
		Pseudo:   "user1",
		Email:    "user1@example.com",
		Password: "password123",
	}

	err := db.Create(&user).Error
	assert.Nil(t, err)

	media := models.Media{
		FileName: "testfile",
		MimeType: "image/png",
		UserID:   user.ID, // Utilisez l'ID de l'utilisateur créé
	}

	err = db.Create(&media).Error
	assert.Nil(t, err)

	server := models.Server{
		Name:       "Test Server",
		Visibility: "public",
		MediaID:    media.ID, // Utilisez l'ID du média créé
		UserID:     user.ID,  // Utilisez l'ID de l'utilisateur créé
	}

	err = db.Create(&server).Error
	assert.Nil(t, err)

	err = db.Delete(&server).Error
	assert.Nil(t, err)

	var deletedServer models.Server
	err = db.First(&deletedServer, "id = ?", server.ID).Error
	assert.NotNil(t, err)
	assert.Equal(t, gorm.ErrRecordNotFound, err)
}
