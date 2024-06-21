package services

import (
	"app/controllers"
	"app/db"
	"app/db/models"
	"fmt"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/go-playground/validator/v10"
	"github.com/golang-jwt/jwt/v4"
	"golang.org/x/crypto/bcrypt"
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

		if err := validate.Struct(payload); err != nil {
			c.Error(err)
			return
		}

		// Check if user exists, if not return 404
		if err := db.GetDB().Where("email = ?", payload.Email).First(&user).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
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

func ChangePassword() gin.HandlerFunc {
	return func(c *gin.Context) {
		var input struct {
			CurrentPassword string `json:"currentPassword" binding:"required"`
			NewPassword     string `json:"newPassword" binding:"required,min=6"`
		}
		if err := c.ShouldBindJSON(&input); err != nil {
			c.Error(err)
			return
		}

		userID := c.Param("id")
		var user models.User
		result := db.GetDB().First(&user, userID)
		if result.Error != nil {
			c.Error(result.Error)
			return
		}

		if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(input.CurrentPassword)); err != nil {
			c.Error(fmt.Errorf("current password is incorrect"))
			return
		}

		user.Password = input.NewPassword
		db.GetDB().Save(&user)

		c.JSON(http.StatusOK, gin.H{"message": "Password updated successfully"})
	}
}

func RegisterFcmToken() gin.HandlerFunc {
	return func(c *gin.Context) {
		var input struct {
			FcmToken string `json:"fcmToken" binding:"required"`
		}
		if err := c.ShouldBindJSON(&input); err != nil {
			c.Error(err)
			return
		}

		//from jwt middleware
		claims, _ := c.Get("jwt_claims")
		jwtClaims := claims.(jwt.MapClaims)
		userID := fmt.Sprintf("%v", jwtClaims["jti"])

		var user models.User
		result := db.GetDB().First(&user, userID)
		if result.Error != nil {
			c.Error(result.Error)
			return
		}

		user.FcmToken = input.FcmToken
		db.GetDB().Save(&user)

		c.JSON(http.StatusOK, gin.H{"message": "FCM token updated successfully"})
	}
}
