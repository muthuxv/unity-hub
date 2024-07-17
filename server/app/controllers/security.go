package controllers

import (
	"bytes"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"strings"
	"time"
	"app/db"
	"app/db/models"
	"log"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v4"
	"github.com/google/uuid"
)

var jwtKey = []byte(os.Getenv("JWT_KEY"))

type CustomClaims struct {
	jwt.RegisteredClaims
	Pseudo string `json:"pseudo"`
}

func GenerateJWT(userID uuid.UUID, email, role, pseudo string) (string, error) {
	expirationTime := time.Now().Add(10000 * time.Hour)
	claims := CustomClaims{
		RegisteredClaims: jwt.RegisteredClaims{
			ID:        fmt.Sprintf("%v", userID),
			Subject:   email,
			ExpiresAt: jwt.NewNumericDate(expirationTime),
			Audience:  []string{role},
		},
		Pseudo: pseudo,
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString(jwtKey)

	if err != nil {
		return "", err
	}

	return tokenString, nil
}

func getJwt(c *gin.Context) (string, error) {
	reqToken := c.GetHeader("Authorization")
	splitToken := strings.Split(reqToken, "Bearer ")
	if len(splitToken) != 2 {
		return "", fmt.Errorf("Malformed token")
	}
	return splitToken[1], nil
}

func GenerateVerificationToken() (string, error) {
	bytes := make([]byte, 16)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	return hex.EncodeToString(bytes), nil
}

func TokenAuthMiddleware(requiredRole string) gin.HandlerFunc {
	return func(c *gin.Context) {
		reqToken, err := getJwt(c)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
			c.Abort()
			return
		}

		token, err := jwt.Parse(reqToken, func(token *jwt.Token) (interface{}, error) {
			if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, http.ErrNotSupported
			}
			return jwtKey, nil
		})

		if err != nil || !token.Valid {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
			c.Abort()
			return
		}

		if claims, ok := token.Claims.(jwt.MapClaims); ok && token.Valid {
			roles := claims["aud"].([]interface{})
			userRole := roles[0].(string)

			if userRole != "admin" && userRole != requiredRole {
				c.JSON(http.StatusForbidden, gin.H{"error": "Insufficient permissions"})
				c.Abort()
				return
			}
		} else {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
			c.Abort()
			return
		}

		c.Set("jwt_claims", token.Claims)
		c.Next()
	}
}

func IsOwner() gin.HandlerFunc {
	return func(c *gin.Context) {
		requestedID := c.Param("id")
		claims, _ := c.Get("jwt_claims")
		jwtClaims := claims.(jwt.MapClaims)

		userID := fmt.Sprintf("%v", jwtClaims["jti"])
		userRole := jwtClaims["aud"].([]interface{})[0].(string)

		if userID != requestedID && userRole != "admin" {
			c.JSON(http.StatusForbidden, gin.H{"error": "Accès refusé"})
			c.Abort()
			return
		}

		c.Next()
	}
}

func FilterBodyMiddleware(fieldsToFilter ...string) gin.HandlerFunc {
	return func(c *gin.Context) {
		if c.Request.Method == "PUT" {
			bodyBytes, err := ioutil.ReadAll(c.Request.Body)
			if err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Erreur lors de la lecture du body"})
				c.Abort()
				return
			}

			c.Request.Body = ioutil.NopCloser(bytes.NewBuffer(bodyBytes))
			var bodyMap map[string]interface{}
			if err := json.Unmarshal(bodyBytes, &bodyMap); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Format du body invalide"})
				c.Abort()
				return
			}

			for _, field := range fieldsToFilter {
				delete(bodyMap, field)
			}

			modifiedBodyBytes, err := json.Marshal(bodyMap)

			if err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Erreur lors de la sérialisation du body modifié"})
				c.Abort()
				return
			}

			c.Request.Body = ioutil.NopCloser(bytes.NewBuffer(modifiedBodyBytes))
			c.Request.ContentLength = int64(len(modifiedBodyBytes))
		}
		c.Next()
	}
}

func PermissionMiddleware(requiredPermission string) gin.HandlerFunc {
	return func(c *gin.Context) {
		reqToken, err := getJwt(c)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
			c.Abort()
			return
		}

		token, err := jwt.Parse(reqToken, func(token *jwt.Token) (interface{}, error) {
			if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, http.ErrNotSupported
			}
			return jwtKey, nil
		})

		if err != nil || !token.Valid {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
			c.Abort()
			return
		}

		if claims, ok := token.Claims.(jwt.MapClaims); ok && token.Valid {
			userIDStr, ok := claims["jti"].(string)
			if !ok {
				c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
				c.Abort()
				return
			}

			userID, err := uuid.Parse(userIDStr)
			if err != nil {
				c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid user ID"})
				c.Abort()
				return
			}

			// Extraire serverID de l'URL
			serverIDStr := c.Param("id")
			serverID, err := uuid.Parse(serverIDStr)
			if err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid server ID"})
				c.Abort()
				return
			}

			var roleUser models.RoleUser
			// Joindre avec la table Role pour filtrer par server_id
			if err := db.GetDB().Joins("JOIN roles ON roles.id = role_users.role_id").Where("role_users.user_id = ? AND roles.server_id = ?", userID, serverID).First(&roleUser).Error; err != nil {
				c.JSON(http.StatusUnauthorized, gin.H{"error": "User role not found"})
				c.Abort()
				return
			}

			var rolePermissions []models.RolePermissions
			if err := db.GetDB().Where("role_id = ?", roleUser.RoleID).Preload("Permissions").Find(&rolePermissions).Error; err != nil {
				c.JSON(http.StatusUnauthorized, gin.H{"error": "Role permissions not found"})
				c.Abort()
				return
			}

			
			isAuthorized := false
			for _, rp := range rolePermissions {
				log.Println(rp.ID)
				if rp.Permissions.Label == requiredPermission {
					if requiredPermission == "admin" && roleUser.Role.Label == "admin" {
						isAuthorized = true
					} else if rp.Power == 1 {
						isAuthorized = true
					}
					break
				}
			}

			if !isAuthorized {
				c.JSON(http.StatusUnauthorized, gin.H{"error": "Insufficient permissions"})
				c.Abort()
				return
			}

			c.Set("jwt_claims", token.Claims)
			c.Next()
		} else {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
			c.Abort()
		}
	}
}
