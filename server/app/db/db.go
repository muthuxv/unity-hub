package db

import (
	"fmt"
	"log"
	"os"
	"sync"

	"app/db/models"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

var db *gorm.DB
var once sync.Once

func InitDB() {
	once.Do(func() {
		dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=disable TimeZone=Europe/Paris",
			os.Getenv("DB_HOST"),
			os.Getenv("DB_USER"),
			os.Getenv("DB_PASS"),
			os.Getenv("DB_NAME"),
			os.Getenv("DB_PORT"))

		var err error
		db, err = gorm.Open(postgres.Open(dsn), &gorm.Config{})
		if err != nil {
			log.Fatalf("Failed to connect to database: %v", err)
		}
	})
}

func MakeMigrations() {
	if db == nil {
		log.Fatal("Database not initialized. Call InitDB first.")
	}
	err := db.AutoMigrate(
		&models.User{},
		&models.Rule{},
		&models.ActiveRule{},
		&models.Media{},
		&models.Channel{},
		&models.Friend{},
		&models.Feature{},
		&models.Invitation{},
		&models.Logs{},
		&models.Message{},
		&models.OnServer{},
		&models.Permissions{},
		&models.React{},
		&models.ReactMessage{},
		&models.Report{},
		&models.Role{},
		&models.RolePermissions{},
		&models.RoleUser{},
		&models.Ban{},
		&models.Group{},
		&models.GroupMember{},
		&models.ChannelChannelPermissions{},
		&models.ChannelPermissions{},
	)

	if err != nil {
		log.Fatalf("Failed to migrate database: %v", err)
	}

	models.CreateInitialReaction(db)

	models.CreateInitialPermissions(db)
	models.CreateInitialChannelPermissions(db)
	models.CreateInitialFeatures(db)

	log.Println("database create")
}

func GetDB() *gorm.DB {
	if db == nil {
		log.Fatal("Database not initialized. Call InitDB first.")
	}
	return db
}
