package services

import (
    "app/db/models"
    "github.com/gin-gonic/gin"
    "net/http"
    "app/controllers"
    "golang.org/x/crypto/bcrypt"
    "github.com/go-playground/validator/v10"
    "app/db"
    "os"
)

var validate = validator.New()

func Register() gin.HandlerFunc {
    return func(c *gin.Context) {
        var inputUser models.User
        if err := c.ShouldBindJSON(&inputUser); err != nil {
            c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
            return
        }

        if validationErr := validate.Struct(inputUser); validationErr != nil {
            c.JSON(http.StatusBadRequest, gin.H{"error": validationErr.Error()})
            return
        }

        if inputUser.Role != "" && inputUser.Role != "user" {
            c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized to assign role other than 'user'"})
            return
        }

        verificationToken, err := controllers.GenerateVerificationToken()
        if err != nil {
            c.JSON(http.StatusInternalServerError, gin.H{"error": "Could not generate verification token"})
            return
        }
        inputUser.VerificationToken = verificationToken

        result := db.GetDB().Create(&inputUser)
        if result.Error != nil {
            c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
            return
        }

        verificationLink := os.Getenv("DOMAIN") + "/verify/" + verificationToken
        body := "Pour activer votre compte, veuillez cliquer sur le lien suivant : " + verificationLink
        controllers.SendEmail(inputUser.Email, "Activation de compte", body)

        c.JSON(http.StatusCreated, inputUser)
    }
}

func Login() gin.HandlerFunc {
    return func(c *gin.Context) {
        var payload struct {
            Email    string `json:"email"`
            Password string `json:"password"`
        }
        var user models.User

        if err := c.ShouldBindJSON(&payload); err != nil {
            c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
            return
        }

        result := db.GetDB().Where("email = ?", payload.Email).First(&user)
        if result.Error != nil {
            c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid email or password"})
            return
        }

        if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(payload.Password)); err != nil {
            c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid email or password"})
            return
        }

        tokenString, err := controllers.GenerateJWT(user.ID, user.Email, user.Role)
        if err != nil {
            c.JSON(http.StatusInternalServerError, gin.H{"error": "Could not generate token"})
            return
        }

        c.JSON(http.StatusOK, gin.H{"token": tokenString})
    }
}

func VerifyAccount() gin.HandlerFunc {
    return func(c *gin.Context) {
        token := c.Param("token")
        var user models.User
        result := db.GetDB().Where("verification_token = ?", token).First(&user)
        if result.Error != nil {
            c.JSON(http.StatusNotFound, gin.H{"error": "Invalid or expired verification token"})
            return
        }

        user.IsVerified = true
        user.VerificationToken = ""
        db.GetDB().Save(&user)

        c.JSON(http.StatusOK, gin.H{"message": "Account verified successfully"})
    }
}
