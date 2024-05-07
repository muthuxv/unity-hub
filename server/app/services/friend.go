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
		result := db.GetDB().Preload("User1").Preload("User2").First(&friend, inputFriend.ID)
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

		// Préparer les données de l'ami pour la réponse
		var friendData = map[string]interface{}{
			"ID":         friend.ID,
			"Status":     friend.Status,
			"UserPseudo": friend.User1.Pseudo,
			"UserMail":   friend.User1.Email,
		}

		c.JSON(http.StatusOK, friendData)
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

		var friends []models.Friend
		result := db.GetDB().Preload("User1").Preload("User2").
			Where("(user_id1 = ? OR user_id2 = ?) AND status = ?", userID, userID, "accepted").Find(&friends)
		if result.Error != nil {
			handleError(c, http.StatusInternalServerError, "Impossible de récupérer les amis")
			return
		}

		friendsResponse := make([]map[string]interface{}, len(friends))
		for i, friend := range friends {
			var friendPseudo string
			if friend.UserID1 == uint(userID) {
				friendPseudo = friend.User2.Pseudo
			} else {
				friendPseudo = friend.User1.Pseudo
			}

			friendData := map[string]interface{}{
				"FriendID":   friend.ID,
				"Status":     friend.Status,
				"UserPseudo": friendPseudo,
				"UserMail":   friend.User1.Email,
			}
			friendsResponse[i] = friendData
		}

		c.JSON(http.StatusOK, friendsResponse)
	}
}

func GetPendingFriendsByUser() gin.HandlerFunc {
	return func(c *gin.Context) {
		userIDStr := c.Param("id")
		userID, err := strconv.Atoi(userIDStr)
		if err != nil {
			handleError(c, http.StatusBadRequest, "ID utilisateur invalide")
			return
		}

		var friends []models.Friend
		result := db.GetDB().Preload("User1").Preload("User2").
			Where("user_id2 = ? AND status = ?", userID, "pending").Find(&friends)
		if result.Error != nil {
			handleError(c, http.StatusInternalServerError, "Impossible de récupérer les demandes d'amis")
			return
		}

		friendsResponse := make([]map[string]interface{}, len(friends))
		for i, friend := range friends {

			friendData := map[string]interface{}{
				"ID":         friend.ID,
				"FriendID":   friend.User1.ID,
				"Status":     friend.Status,
				"UserPseudo": friend.User1.Pseudo,
			}
			friendsResponse[i] = friendData
		}

		c.JSON(http.StatusOK, friendsResponse)
	}
}

func GetPendingFriendsFromUser() gin.HandlerFunc {
	return func(c *gin.Context) {
		userIDStr := c.Param("id")
		userID, err := strconv.Atoi(userIDStr)
		if err != nil {
			handleError(c, http.StatusBadRequest, "ID utilisateur invalide")
			return
		}

		var friends []models.Friend
		result := db.GetDB().Preload("User1").Preload("User2").
			Where("user_id1 = ? AND status = ?", userID, "pending").Find(&friends)
		if result.Error != nil {
			handleError(c, http.StatusInternalServerError, "Impossible de récupérer les demandes d'amis")
			return
		}

		friendsResponse := make([]map[string]interface{}, len(friends))
		for i, friend := range friends {

			friendData := map[string]interface{}{
				"ID":         friend.ID,
				"FriendID":   friend.User2.ID,
				"Status":     friend.Status,
				"UserPseudo": friend.User2.Pseudo,
			}
			friendsResponse[i] = friendData
		}

		c.JSON(http.StatusOK, friendsResponse)
	}
}

func CreateFriendRequest() gin.HandlerFunc {
	return func(c *gin.Context) {
		var input struct {
			UserID     uint   `json:"userId"`     // ID of the user sending the request
			UserPseudo string `json:"userPseudo"` // Pseudo of the user to be added as a friend
		}

		if err := c.ShouldBindJSON(&input); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"message": "Invalid JSON data"})
			return
		}

		// Check for the existence of the user with the given pseudo
		var user models.User
		result := db.GetDB().Where("pseudo = ?", input.UserPseudo).First(&user)
		if result.Error != nil {
			c.JSON(http.StatusNotFound, gin.H{"message": "L'utilisateur n'existe pas"})
			return
		}

		// Prevent sending a friend request to oneself
		if input.UserID == user.ID {
			c.JSON(http.StatusBadRequest, gin.H{"message": "Vous ne pouvez pas vous ajouter en tant qu'ami"})
			return
		}

		// Check if there's already a pending or accepted friend request between these two users
		var existingFriend models.Friend
		result = db.GetDB().Where("((user_id1 = ? AND user_id2 = ?) OR (user_id1 = ? AND user_id2 = ?)) AND status = 'pending'",
			input.UserID, user.ID, user.ID, input.UserID).First(&existingFriend)

		if result.Error == nil {
			c.JSON(http.StatusConflict, gin.H{"message": "Demande d'ami déjà envoyée"})
			return
		}

		// Check if the users are already friends
		var existingFriendship models.Friend
		result = db.GetDB().Where("((user_id1 = ? AND user_id2 = ?) OR (user_id1 = ? AND user_id2 = ?)) AND status = 'accepted'",
			input.UserID, user.ID, user.ID, input.UserID).First(&existingFriendship)

		if result.Error == nil {
			c.JSON(http.StatusConflict, gin.H{"message": "Vous êtes déjà amis avec cet utilisateur"})
			return
		}

		// Create the friend request
		friend := models.Friend{
			UserID1: input.UserID,
			UserID2: user.ID,
			Status:  "pending", // Initial status of the friend request
		}

		result = db.GetDB().Create(&friend)
		if result.Error != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to send friend request"})
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "Demande d'ami envoyée avec succès", "friend": friend})
	}
}
