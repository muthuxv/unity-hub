package testutils

import (
	"app/db/models"
	"fmt"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"log"
	"os"
	"strings"
	"sync"
)

var db *gorm.DB
var once sync.Once

func InitTestDB() {
	once.Do(func() {
		// Définir les variables d'environnement directement dans le code
		os.Setenv("DB_HOST", "localhost")
		os.Setenv("DB_USER", "user")
		os.Setenv("DB_PASS", "!MuthuTheBest2024!")
		os.Setenv("DB_NAME", "app")
		os.Setenv("DB_PORT", "5432")

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

func MakeTestMigrations() {
	if db == nil {
		log.Fatal("Database not initialized. Call InitDB first.")
	}
	err := db.AutoMigrate(
		&models.User{},
		&models.Rule{},
		&models.ActiveRule{},
		&models.Media{},
		&models.Channel{},
		&models.Event{},
		&models.Server{},
		&models.EventServer{},
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
		&models.Theme{},
		&models.ThemeServer{},
		&models.Ban{},
		&models.Group{},
		&models.GroupMember{},
	)

	if err != nil {
		log.Fatalf("Failed to migrate database: %v", err)
	}

	log.Println("database create")
}

func ClearTables() {
	if db == nil {
		log.Fatal("Database not initialized. Call InitTestDB first.")
	}
	tables := []interface{}{
		&models.User{},
		&models.Friend{},
		&models.Ban{},
		&models.Role{},
		&models.Server{},
		&models.Invitation{},
		// Ajoutez d'autres modèles si nécessaire
	}

	// Désactiver les contraintes de clé étrangère
	db.Exec("SET session_replication_role = 'replica'")

	for _, table := range tables {
		tableName := db.NamingStrategy.TableName(fmt.Sprintf("%T", table)[1:]) // Retirer l'astérisque du type
		tableName = strings.TrimPrefix(tableName, "models.")                   // Retirer le préfixe "models."
		// retirer le _
		tableName = strings.Replace(tableName, "_", "", -1)
		db.Exec(fmt.Sprintf("DELETE FROM %s", tableName))
	}

	db.Exec("SET session_replication_role = 'origin'")
}

func SetupTestDB() *gorm.DB {
	InitTestDB()
	MakeTestMigrations()
	ClearTables()
	return GetTestDB()
}

func GetTestDB() *gorm.DB {
	if db == nil {
		log.Fatal("Database not initialized. Call InitDB first.")
	}
	return db
}
