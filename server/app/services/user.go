package services

import (
    "fmt"
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
            c.Error(err)
            return
        }

        if validationErr := validate.Struct(inputUser); validationErr != nil {
            c.Error(validationErr)
            return
        }

        if inputUser.Role != "" && inputUser.Role != "user" {
            c.Error(fmt.Errorf("Unauthorized to assign role other than 'user'"))
            return
        }

        var existingUser models.User
        if err := db.GetDB().Where("email = ?", inputUser.Email).First(&existingUser).Error; err == nil {
            c.JSON(http.StatusConflict, gin.H{"error": "User with this email already exists"})
            return
        }

        verificationToken, err := controllers.GenerateVerificationToken()
        if err != nil {
            c.Error(err)
            return
        }
        inputUser.VerificationToken = verificationToken

        hashedPassword, err := bcrypt.GenerateFromPassword([]byte(inputUser.Password), bcrypt.DefaultCost)
        if err != nil {
            c.Error(err)
            return
        }
        inputUser.Password = string(hashedPassword)

        result := db.GetDB().Create(&inputUser)
        if result.Error != nil {
            c.Error(result.Error)
            return
        }

        verificationLink := os.Getenv("DOMAIN") + "/verify/" + verificationToken
        body := "To activate your account, please click on the following link: " + verificationLink
        controllers.SendEmail(inputUser.Email, "Account Activation", body)

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
            c.Error(err)
            return
        }

        result := db.GetDB().Where("email = ?", payload.Email).First(&user)
        if result.Error != nil {
            c.Error(result.Error)
            return
        }

        if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(payload.Password)); err != nil {
            c.Error(err)
            return
        }

        tokenString, err := controllers.GenerateJWT(user.ID, user.Email, user.Role)
        if err != nil {
            c.Error(err)
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
            c.Error(result.Error)
            return
        }

        user.IsVerified = true
        user.VerificationToken = ""
        db.GetDB().Save(&user)

        c.JSON(http.StatusOK, gin.H{"message": "Account verified successfully"})
    }
}
