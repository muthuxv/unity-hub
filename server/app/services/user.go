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

// Register godoc
// @Summary Register a new user
// @Description Register a new user with email and pseudo
// @Tags auth
// @Accept json
// @Produce json
// @Param user body models.User true "User info"
// @Success 201 {object} models.UserSwagger
// @Failure 400 {object} models.ErrorUserResponse
// @Failure 409 {object} models.ErrorUserResponse
// @Router /register [post]
func Register() gin.HandlerFunc {
	return func(c *gin.Context) {
		var inputUser models.User
		if err := c.ShouldBindJSON(&inputUser); err != nil {
			c.Error(err)
			return
		}

		// Vérification si les champs sont vides
		if inputUser.Email == "" || inputUser.Pseudo == "" || inputUser.Password == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Email, Pseudo, and Password are required"})
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
			c.JSON(http.StatusConflict, models.ErrorUserResponse{Error: "User with this email already exists"})
			return
		}

		if err := db.GetDB().Where("pseudo = ?", inputUser.Pseudo).First(&existingUser).Error; err == nil {
			c.JSON(http.StatusConflict, models.ErrorUserResponse{Error: "User with this pseudo already exists"})
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

// Login godoc
// @Summary Login a user
// @Description Login a user with email and password
// @Tags auth
// @Accept json
// @Produce json
// @Param credentials body models.LoginPayload true "Login credentials"
// @Success 200 {object} models.TokenResponse
// @Failure 400 {object} models.ErrorUserResponse
// @Failure 404 {object} models.ErrorUserResponse
// @Router /login [post]
func CreateUserByAdmin() gin.HandlerFunc {
	return func(c *gin.Context) {
		var inputUser models.User
		if err := c.ShouldBindJSON(&inputUser); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input"})
			return
		}

		// Vérification si les champs sont vides
		if inputUser.Email == "" || inputUser.Pseudo == "" || inputUser.Password == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Email, Pseudo, and Password are required"})
			return
		}

		if validationErr := validate.Struct(inputUser); validationErr != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input structure"})
			return
		}

		// Administrateurs peuvent définir n'importe quel rôle
		var existingUser models.User
		if err := db.GetDB().Where("email = ?", inputUser.Email).First(&existingUser).Error; err == nil {
			c.JSON(http.StatusConflict, gin.H{"error": "User with this email already exists"})
			return
		}

		if err := db.GetDB().Where("pseudo = ?", inputUser.Pseudo).First(&existingUser).Error; err == nil {
			c.JSON(http.StatusConflict, gin.H{"error": "User with this pseudo already exists"})
			return
		}

		// Optionnel : Vous pouvez générer un jeton de vérification ou d'autres données requises ici

		result := db.GetDB().Create(&inputUser)
		if result.Error != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user"})
			return
		}

		c.JSON(http.StatusCreated, inputUser)
	}
}

func Login() gin.HandlerFunc {
	return func(c *gin.Context) {
		var payload models.LoginPayload
		var user models.User

		if err := c.ShouldBindJSON(&payload); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input"})
			return
		}

		if err := validate.Struct(payload); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input structure"})
			return
		}

		payload.Email = strings.ToLower(payload.Email)

		if err := db.GetDB().Where("email = ?", payload.Email).First(&user).Error; err != nil {
			c.JSON(http.StatusNotFound, models.ErrorUserResponse{Error: "User not found"})
			return
		}

		if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(payload.Password)); err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Incorrect password"})
			return
		}

		tokenString, err := controllers.GenerateJWT(user.ID, user.Email, user.Role, user.Pseudo)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
			return
		}

		c.JSON(http.StatusOK, models.TokenResponse{Token: tokenString})
	}
}

// VerifyAccount godoc
// @Summary Verify a user account
// @Description Verify a user account using the verification token
// @Tags auth
// @Accept json
// @Produce json
// @Param token path string true "Verification token"
// @Success 200 {object} models.SuccessResponse
// @Failure 400 {object} models.ErrorUserResponse
// @Router /verify/{token} [get]
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

		c.JSON(http.StatusOK, models.SuccessResponse{Message: "Account verified successfully"})
	}
}

// ChangePassword godoc
// @Summary Change user password
// @Description Change the password of an existing user
// @Tags user
// @Accept json
// @Produce json
// @Param id path string true "User ID"
// @Param password body models.ChangePasswordPayload true "Password info"
// @Success 200 {object} models.SuccessResponse
// @Failure 400 {object} models.ErrorUserResponse
// @Failure 404 {object} models.ErrorUserResponse
// @Failure 401 {object} models.ErrorUserResponse
// @Router /user/{id}/password [put]
func ChangePassword() gin.HandlerFunc {
	return func(c *gin.Context) {
		var input models.ChangePasswordPayload
		if err := c.ShouldBindJSON(&input); err != nil {
			c.JSON(http.StatusBadRequest, models.ErrorUserResponse{Error: "Invalid input"})
			return
		}

		userID := c.Param("id")
		var user models.User
		result := db.GetDB().First(&user, userID)
		if result.Error != nil {
			c.JSON(http.StatusNotFound, models.ErrorUserResponse{Error: "User not found"})
			return
		}

		if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(input.CurrentPassword)); err != nil {
			c.JSON(http.StatusUnauthorized, models.ErrorUserResponse{Error: "Current password is incorrect"})
			return
		}

		user.Password = input.NewPassword
		db.GetDB().Save(&user)

		c.JSON(http.StatusOK, models.SuccessResponse{Message: "Password updated successfully"})
	}
}

// UpdateUserData godoc
// @Summary Update user data
// @Description Update the data of an existing user
// @Tags user
// @Accept json
// @Produce json
// @Param id path string true "User ID"
// @Param data body models.UpdateUserDataPayload true "User data"
// @Success 200 {object} models.UserSwagger
// @Failure 400 {object} models.ErrorUserResponse
// @Failure 404 {object} models.ErrorUserResponse
// @Failure 409 {object} models.ErrorUserResponse
// @Router /user/{id} [put]
func UpdateUserAdmin() gin.HandlerFunc {
	return func(c *gin.Context) {
		userIDStr := c.Param("id")

		userID, err := uuid.Parse(userIDStr)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
			return
		}

		var input struct {
			Pseudo string `json:"pseudo"`
			Email  string `json:"email"`
			Role   string `json:"role"`
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
		}

		if input.Email != "" && input.Email != user.Email {
			var existingUser models.User
			if err := db.GetDB().Where("email = ?", input.Email).First(&existingUser).Error; err == nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Email already exists"})
				return
			}
			user.Email = input.Email
		}

		if input.Role != "" {
			user.Role = input.Role
		}

		if err := db.GetDB().Save(&user).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update user"})
			return
		}

		c.JSON(http.StatusOK, user)
	}
}

func UpdateUserData() gin.HandlerFunc {
	return func(c *gin.Context) {
		userIDStr := c.Param("id")

		userID, err := uuid.Parse(userIDStr)
		if err != nil {
			c.JSON(http.StatusBadRequest, models.ErrorUserResponse{Error: "Invalid user ID"})
			return
		}

		var input models.UpdateUserDataPayload

		if err := c.ShouldBindJSON(&input); err != nil {
			c.JSON(http.StatusBadRequest, models.ErrorUserResponse{Error: "Invalid input"})
			return
		}

		var user models.User
		result := db.GetDB().Where("id = ?", userID).First(&user)
		if result.Error != nil {
			if errors.Is(result.Error, gorm.ErrRecordNotFound) {
				c.JSON(http.StatusNotFound, models.ErrorUserResponse{Error: "User not found"})
			} else {
				c.Error(result.Error)
			}
			return
		}

		if input.Pseudo != "" && input.Pseudo != user.Pseudo {
			var existingUser models.User
			if err := db.GetDB().Where("pseudo = ?", input.Pseudo).First(&existingUser).Error; err == nil {
				c.JSON(http.StatusBadRequest, models.ErrorUserResponse{Error: "Pseudo already exists"})
				return
			}

			user.Pseudo = input.Pseudo

			if err := db.GetDB().Model(&user).Updates(models.User{Pseudo: input.Pseudo}).Error; err != nil {
				c.JSON(http.StatusInternalServerError, models.ErrorUserResponse{Error: "Failed to update pseudo"})
				return
			}
		}

		if input.Profile != "" {
			user.Profile = input.Profile

			if err := db.GetDB().Model(&user).Updates(models.User{Profile: input.Profile}).Error; err != nil {
				c.JSON(http.StatusInternalServerError, models.ErrorUserResponse{Error: "Failed to update profile"})
				return
			}
		}

		c.JSON(http.StatusOK, user)
	}
}

// RegisterFcmToken godoc
// @Summary Register FCM token
// @Description Register a Firebase Cloud Messaging token for push notifications
// @Tags user
// @Accept json
// @Produce json
// @Param fcmToken body models.FcmTokenPayload true "FCM token"
// @Success 200 {object} models.SuccessResponse
// @Failure 400 {object} models.ErrorUserResponse
// @Failure 404 {object} models.ErrorUserResponse
// @Router /user/fcm-token [post]
func RegisterFcmToken() gin.HandlerFunc {
	return func(c *gin.Context) {
		var input models.FcmTokenPayload
		if err := c.ShouldBindJSON(&input); err != nil {
			c.JSON(http.StatusBadRequest, models.ErrorUserResponse{Error: err.Error()})
			return
		}

		claims, exists := c.Get("jwt_claims")
		if !exists {
			c.JSON(http.StatusUnauthorized, models.ErrorUserResponse{Error: "JWT claims not found"})
			return
		}
		jwtClaims, ok := claims.(jwt.MapClaims)
		if !ok {
			c.JSON(http.StatusUnauthorized, models.ErrorUserResponse{Error: "Invalid JWT claims"})
			return
		}
		userID, ok := jwtClaims["jti"].(string)
		if !ok {
			c.JSON(http.StatusUnauthorized, models.ErrorUserResponse{Error: "Invalid user ID in JWT claims"})
			return
		}

		var user models.User
		result := db.GetDB().Where("id = ?", userID).First(&user)
		if result.Error != nil {
			if errors.Is(result.Error, gorm.ErrRecordNotFound) {
				c.JSON(http.StatusNotFound, models.ErrorUserResponse{Error: "User not found"})
			} else {
				c.JSON(http.StatusInternalServerError, models.ErrorUserResponse{Error: result.Error.Error()})
			}
			return
		}

		user.FcmToken = input.FcmToken
		if err := db.GetDB().Model(&user).Update("fcm_token", input.FcmToken).Error; err != nil {
			c.JSON(http.StatusInternalServerError, models.ErrorUserResponse{Error: "Failed to update FCM token"})
			return
		}

		c.JSON(http.StatusOK, models.SuccessResponse{Message: "FCM token updated successfully"})
	}
}

func GetUserByPseudo() gin.HandlerFunc {
	return func(c *gin.Context) {
		pseudo := c.Param("pseudo")

		if pseudo == "" || !isValidPseudo(pseudo) {
			c.JSON(http.StatusBadRequest, models.ErrorUserResponse{Error: "Pseudo invalide"})
			return
		}

		var user models.User

		result := db.GetDB().Where("pseudo = ?", pseudo).First(&user)
		if result.Error != nil {
			if errors.Is(result.Error, gorm.ErrRecordNotFound) {
				c.JSON(http.StatusNotFound, models.ErrorUserResponse{Error: "Utilisateur non trouvé"})
			} else {
				c.JSON(http.StatusInternalServerError, models.ErrorUserResponse{Error: "Erreur interne du serveur"})
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
