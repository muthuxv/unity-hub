package services

import (
	"app/controllers"
	"app/db"
	"app/db/models"
	"errors"
	"fmt"
	"net/http"
	"os"
	"regexp"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/go-playground/validator/v10"
	"github.com/golang-jwt/jwt/v4"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
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
			c.Error(fmt.Errorf("unauthorized to assign role other than 'user'"))
			return
		}

		var existingUser models.User
		if err := db.GetDB().Where("email = ?", inputUser.Email).First(&existingUser).Error; err == nil {
			c.JSON(http.StatusConflict, gin.H{"error": "User with this email already exists"})
			return
		}

		if err := db.GetDB().Where("pseudo = ?", inputUser.Pseudo).First(&existingUser).Error; err == nil {
			c.JSON(http.StatusConflict, gin.H{"error": "User with this pseudo already exists"})
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

		payload.Email = strings.ToLower(payload.Email)

		if err := db.GetDB().Where("email = ?", payload.Email).First(&user).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
			return
		}

		if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(payload.Password)); err != nil {
			c.Error(err)
			return
		}

		tokenString, err := controllers.GenerateJWT(user.ID, user.Email, user.Role, user.Pseudo)
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
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input"})
			return
		}

		userID := c.Param("id")
		var user models.User
		result := db.GetDB().First(&user, userID)
		if result.Error != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
			return
		}

		if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(input.CurrentPassword)); err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Current password is incorrect"})
			return
		}

		user.Password = input.NewPassword
		db.GetDB().Save(&user)

		c.JSON(http.StatusOK, gin.H{"message": "Password updated successfully"})
	}
}

func UpdateUserData() gin.HandlerFunc {
	return func(c *gin.Context) {
		userIDStr := c.Param("id")

		userID, err := uuid.Parse(userIDStr)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
			return
		}

		var input struct {
			Pseudo string `json:"pseudo"`
		}

		if err := c.ShouldBindJSON(&input); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input"})
			return
		}

		var user models.User
		result := db.GetDB().Where("id = ?", userID).First(&user)
		if result.Error != nil {
			if errors.Is(result.Error, gorm.ErrRecordNotFound) {
				c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
			} else {
				c.Error(result.Error)
			}
			return
		}

		if input.Pseudo != "" && input.Pseudo != user.Pseudo {
			var existingUser models.User
			if err := db.GetDB().Where("pseudo = ?", input.Pseudo).First(&existingUser).Error; err == nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Pseudo already exists"})
				return
			}

			user.Pseudo = input.Pseudo

			if err := db.GetDB().Model(&user).Updates(models.User{Pseudo: input.Pseudo}).Error; err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update pseudo"})
				return
			}
		}

		c.JSON(http.StatusOK, user)
	}
}

func RegisterFcmToken() gin.HandlerFunc {
	return func(c *gin.Context) {
		var input struct {
			FcmToken string `json:"fcmToken" binding:"required"`
		}
		if err := c.ShouldBindJSON(&input); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		claims, exists := c.Get("jwt_claims")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "JWT claims not found"})
			return
		}
		jwtClaims, ok := claims.(jwt.MapClaims)
		if !ok {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid JWT claims"})
			return
		}
		userID, ok := jwtClaims["jti"].(string)
		if !ok {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid user ID in JWT claims"})
			return
		}

		var user models.User
		result := db.GetDB().Where("id = ?", userID).First(&user)
		if result.Error != nil {
			if errors.Is(result.Error, gorm.ErrRecordNotFound) {
				c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
			} else {
				c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
			}
			return
		}

		user.FcmToken = input.FcmToken
		if err := db.GetDB().Model(&user).Update("fcm_token", input.FcmToken).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update FCM token"})
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "FCM token updated successfully"})
	}
}

func GetUserByPseudo() gin.HandlerFunc {
	return func(c *gin.Context) {
		pseudo := c.Param("pseudo")

		if pseudo == "" || !isValidPseudo(pseudo) {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Pseudo invalide"})
			return
		}

		var user models.User

		result := db.GetDB().Where("pseudo = ?", pseudo).First(&user)
		if result.Error != nil {
			if errors.Is(result.Error, gorm.ErrRecordNotFound) {
				c.JSON(http.StatusNotFound, gin.H{"error": "Utilisateur non trouvé"})
			} else {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Erreur interne du serveur"})
			}
			return
		}

		userResponse := map[string]interface{}{
			"id":        user.ID,
			"pseudo":    user.Pseudo,
			"email":     user.Email,
			"profile":   user.Profile,
			"fcm_token": user.FcmToken,
			"createdAt": user.CreatedAt,
			"updatedAt": user.UpdatedAt,
		}

		c.JSON(http.StatusOK, userResponse)
	}
}

func isValidPseudo(pseudo string) bool {
	re := regexp.MustCompile("^[a-zA-Z0-9_]+$")
	return re.MatchString(pseudo)
}
