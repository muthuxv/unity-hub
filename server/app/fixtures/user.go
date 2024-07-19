package fixtures

import "app/db/models"

var Users = []models.User{
    {Email: "admin@example.com", Password: "Azerty1234", Role: "admin"},
    {Email: "user@example.com", Password: "Azerty1234", Role: "user"},
}
