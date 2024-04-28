package services

import (
	"app/db"
	"app/db/models"
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
)

func AcceptFriend() gin.HandlerFunc {
	return func(c *gin.Context) {
		var inputFriend models.Friend
		if err := c.ShouldBindJSON(&inputFriend); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid JSON data"})
			return
		}

		// Vérification de l'existence
		var friend models.Friend
		result := db.GetDB().First(&friend, inputFriend.ID)
		if result.Error != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Friend request not found"})
			return
		}

		// Vérification de l'état pour éviter des modifications redondantes
		if friend.Status == "accepted" {
			c.JSON(http.StatusBadRequest, gin.H{"message": "Friend request already accepted"})
			return
		}

		// Mise à jour de l'état
		result = db.GetDB().Model(&friend).Update("status", "accepted")
		if result.Error != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update friend request"})
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "Friend request accepted"})
	}
}

func RefuseFriend() gin.HandlerFunc {
	return func(c *gin.Context) {
		var inputFriend models.Friend
		if err := c.ShouldBindJSON(&inputFriend); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid JSON data"})
			return
		}

		// Vérification de l'existence de la demande d'ami
		var friend models.Friend
		result := db.GetDB().First(&friend, inputFriend.ID)
		if result.Error != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Friend request not found"})
			return
		}

		// Vérification de l'état pour éviter des modifications redondantes
		if friend.Status == "refused" {
			c.JSON(http.StatusBadRequest, gin.H{"message": "Friend request already refused"})
			return
		}

		// Mise à jour de l'état en "refused"
		result = db.GetDB().Model(&friend).Update("status", "refused")
		if result.Error != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update friend request"})
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "Friend request refused"})
	}
}

func SearchUser() gin.HandlerFunc {
	return func(c *gin.Context) {
		pseudo := c.Param("pseudo")
		var users []models.User

		// Normaliser l'entrée pour ignorer la casse
		pseudo = strings.ToLower(pseudo)

		// Utiliser LIKE pour chercher des pseudos qui commencent par la chaîne spécifiée, insensible à la casse
		result := db.GetDB().Where("LOWER(pseudo) LIKE ?", pseudo+"%").Find(&users)
		if result.Error != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to search users"})
			return
		}

		// Vérifier si aucun utilisateur n'a été trouvé
		if len(users) == 0 {
			c.JSON(http.StatusOK, gin.H{"message": "No users found starting with the given pseudo"})
			return
		}

		c.JSON(http.StatusOK, users)
	}
}

func GetFriendsByUser() gin.HandlerFunc {
	return func(c *gin.Context) {
		userIDStr := c.Param("id")
		userID, err := strconv.Atoi(userIDStr)
		if err != nil {
			handleError(c, http.StatusBadRequest, "ID utilisateur invalide")
			return
		}

		// récupérer les amis de l'utilisateur user_id1 et avec le status "accepted"
		var friends []models.Friend
		result := db.GetDB().Where("user_id1 = ? AND status = ?", userID, "accepted").Find(&friends)
		if result.Error != nil {
			handleError(c, http.StatusInternalServerError, "Impossible de récupérer les amis")
			return
		}

		c.JSON(http.StatusOK, friends)
	}
}
