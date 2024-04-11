package main

import (
    "app/db"
    "app/fixtures"
    "log"
    "golang.org/x/crypto/bcrypt"
)

func main() {
    db.InitDB()
    database := db.GetDB() 

    userIDs := make([]uint, len(fixtures.Users))

    for i, user := range fixtures.Users {
        hashedPassword, err := bcrypt.GenerateFromPassword([]byte(user.Password), bcrypt.DefaultCost)
        if err != nil {
            log.Fatalf("Erreur lors du hachage du mot de passe: %v", err)
        }
        user.Password = string(hashedPassword)
        
        if result := database.Create(&user); result.Error != nil {
            log.Fatalf("Erreur lors de l'insertion de l'utilisateur: %v", result.Error)
        } else {
            userIDs[i] = user.ID 
        }
    }

    if len(userIDs) < len(fixtures.Media) {
        log.Fatalf("Pas assez d'utilisateurs pour lier les médias.")
    }

    for i, media := range fixtures.Media {
        media.UserID = userIDs[i]
        // Utiliser l'instance de *gorm.DB pour appeler Create
        if result := database.Create(&media); result.Error != nil {
            log.Fatalf("Erreur lors de l'insertion du média: %v", result.Error)
        }
    }

    log.Println("Fixtures chargées avec succès.")
}
