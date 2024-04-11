package db

import (
    "fmt"
    "log"
    "os"
    "sync"

    "gorm.io/driver/postgres"
    "gorm.io/gorm"
    "app/db/models"
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
    db.AutoMigrate(&models.User{})
    db.AutoMigrate(&models.Notification{})
    db.AutoMigrate(&models.ActiveNotification{})
    db.AutoMigrate(&models.Media{})
    log.Println("database create")
}

func GetDB() *gorm.DB {
    if db == nil {
        log.Fatal("Database not initialized. Call InitDB first.")
    }
    return db
}
