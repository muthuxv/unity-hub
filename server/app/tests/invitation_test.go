package tests

import (
	"app/db/models"
	"app/testutils"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"gorm.io/gorm"
	"testing"
	"time"
)

func TestCreateInvitation(t *testing.T) {
	db := testutils.SetupTestDB()

	// Prérequis : Créer des utilisateurs, un média et un serveur
	sender := models.User{
		Pseudo:   "sender",
		Email:    "sender@example.com",
		Password: "password123",
	}
	receiver := models.User{
		Pseudo:   "receiver",
		Email:    "receiver@example.com",
		Password: "password123",
	}
	err := db.Create(&sender).Error
	assert.Nil(t, err)
	err = db.Create(&receiver).Error
	assert.Nil(t, err)

	media := models.Media{
		FileName: "testfile",
		MimeType: "image/png",
		UserID:   sender.ID, // Assurez-vous de référencer un utilisateur valide
	}
	err = db.Create(&media).Error
	assert.Nil(t, err)

	server := models.Server{
		Name:       "Test Server",
		Visibility: "public",
		MediaID:    media.ID,  // Assurez-vous de référencer un média valide
		UserID:     sender.ID, // Assurez-vous de référencer un utilisateur valide
	}
	err = db.Create(&server).Error
	assert.Nil(t, err)

	invitation := models.Invitation{
		Link:           "http://example.com/invite",
		IsAccepted:     false,
		Expire:         time.Now().Add(24 * time.Hour),
		UserSenderID:   sender.ID,
		UserReceiverID: receiver.ID,
		ServerID:       server.ID,
	}
	err = db.Create(&invitation).Error
	assert.Nil(t, err)
	assert.NotEqual(t, uuid.Nil, invitation.ID)
}

func TestReadInvitation(t *testing.T) {
	db := testutils.SetupTestDB()

	// Prérequis : Créer des utilisateurs, un média et un serveur
	sender := models.User{
		Pseudo:   "sender",
		Email:    "sender@example.com",
		Password: "password123",
	}
	receiver := models.User{
		Pseudo:   "receiver",
		Email:    "receiver@example.com",
		Password: "password123",
	}
	err := db.Create(&sender).Error
	assert.Nil(t, err)
	err = db.Create(&receiver).Error
	assert.Nil(t, err)

	media := models.Media{
		FileName: "testfile",
		MimeType: "image/png",
		UserID:   sender.ID,
	}
	err = db.Create(&media).Error
	assert.Nil(t, err)

	server := models.Server{
		Name:       "Test Server",
		Visibility: "public",
		MediaID:    media.ID,
		UserID:     sender.ID,
	}
	err = db.Create(&server).Error
	assert.Nil(t, err)

	invitation := models.Invitation{
		Link:           "http://example.com/invite",
		IsAccepted:     false,
		Expire:         time.Now().Add(24 * time.Hour),
		UserSenderID:   sender.ID,
		UserReceiverID: receiver.ID,
		ServerID:       server.ID,
	}
	err = db.Create(&invitation).Error
	assert.Nil(t, err)

	var fetchedInvitation models.Invitation
	err = db.Preload("UserSender").Preload("UserReceiver").Preload("Server").First(&fetchedInvitation, "id = ?", invitation.ID).Error
	assert.Nil(t, err)
	assert.Equal(t, invitation.ID, fetchedInvitation.ID)
	assert.Equal(t, invitation.Link, fetchedInvitation.Link)
	assert.Equal(t, invitation.IsAccepted, fetchedInvitation.IsAccepted)
	assert.Equal(t, invitation.UserSenderID, fetchedInvitation.UserSenderID)
	assert.Equal(t, invitation.UserReceiverID, fetchedInvitation.UserReceiverID)
	assert.Equal(t, invitation.ServerID, fetchedInvitation.ServerID)
}

func TestUpdateInvitation(t *testing.T) {
	db := testutils.SetupTestDB()

	// Prérequis : Créer des utilisateurs, un média et un serveur
	sender := models.User{
		Pseudo:   "sender",
		Email:    "sender@example.com",
		Password: "password123",
	}
	receiver := models.User{
		Pseudo:   "receiver",
		Email:    "receiver@example.com",
		Password: "password123",
	}
	err := db.Create(&sender).Error
	assert.Nil(t, err)
	err = db.Create(&receiver).Error
	assert.Nil(t, err)

	media := models.Media{
		FileName: "testfile",
		MimeType: "image/png",
		UserID:   sender.ID,
	}
	err = db.Create(&media).Error
	assert.Nil(t, err)

	server := models.Server{
		Name:       "Test Server",
		Visibility: "public",
		MediaID:    media.ID,
		UserID:     sender.ID,
	}
	err = db.Create(&server).Error
	assert.Nil(t, err)

	invitation := models.Invitation{
		Link:           "http://example.com/invite",
		IsAccepted:     false,
		Expire:         time.Now().Add(24 * time.Hour),
		UserSenderID:   sender.ID,
		UserReceiverID: receiver.ID,
		ServerID:       server.ID,
	}
	err = db.Create(&invitation).Error
	assert.Nil(t, err)

	invitation.IsAccepted = true
	err = db.Save(&invitation).Error
	assert.Nil(t, err)

	var updatedInvitation models.Invitation
	err = db.First(&updatedInvitation, "id = ?", invitation.ID).Error
	assert.Nil(t, err)
	assert.Equal(t, true, updatedInvitation.IsAccepted)
}

func TestDeleteInvitation(t *testing.T) {
	db := testutils.SetupTestDB()

	// Prérequis : Créer des utilisateurs, un média et un serveur
	sender := models.User{
		Pseudo:   "sender",
		Email:    "sender@example.com",
		Password: "password123",
	}
	receiver := models.User{
		Pseudo:   "receiver",
		Email:    "receiver@example.com",
		Password: "password123",
	}
	err := db.Create(&sender).Error
	assert.Nil(t, err)
	err = db.Create(&receiver).Error
	assert.Nil(t, err)

	media := models.Media{
		FileName: "testfile",
		MimeType: "image/png",
		UserID:   sender.ID,
	}
	err = db.Create(&media).Error
	assert.Nil(t, err)

	server := models.Server{
		Name:       "Test Server",
		Visibility: "public",
		MediaID:    media.ID,
		UserID:     sender.ID,
	}
	err = db.Create(&server).Error
	assert.Nil(t, err)

	invitation := models.Invitation{
		Link:           "http://example.com/invite",
		IsAccepted:     false,
		Expire:         time.Now().Add(24 * time.Hour),
		UserSenderID:   sender.ID,
		UserReceiverID: receiver.ID,
		ServerID:       server.ID,
	}
	err = db.Create(&invitation).Error
	assert.Nil(t, err)

	err = db.Delete(&invitation).Error
	assert.Nil(t, err)

	var deletedInvitation models.Invitation
	err = db.First(&deletedInvitation, "id = ?", invitation.ID).Error
	assert.NotNil(t, err)
	assert.Equal(t, gorm.ErrRecordNotFound, err)
}
