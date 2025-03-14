package services

import (
	"app/db"
	"app/db/models"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

func AcceptFriend() gin.HandlerFunc {
	return func(c *gin.Context) {
		var inputFriend struct {
			ID      uuid.UUID `json:"id"`
			UserID2 uuid.UUID `json:"userId2"`
		}
		if err := c.ShouldBindJSON(&inputFriend); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"message": "Invalide JSON data"})
			return
		}

		var friend models.Friend
		result := db.GetDB().Where("id = ?", inputFriend.ID).Preload("User1").Preload("User2").First(&friend)
		if result.Error != nil {
			c.JSON(http.StatusNotFound, gin.H{"message": "Demande d'ami non trouvée"})
			return
		}

		if friend.UserID2 != inputFriend.UserID2 {
			c.JSON(http.StatusUnauthorized, gin.H{"message": "Demande d'ami non autorisée"})
			return
		}

		if friend.Status == "accepted" {
			c.JSON(http.StatusBadRequest, gin.H{"message": "Demande d'ami déjà acceptée, impossible de refuser"})
			return
		}

		if friend.Status == "accepted" {
			c.JSON(http.StatusBadRequest, gin.H{"message": "Demande d'ami déjà acceptée"})
			return
		}

		result = db.GetDB().Model(&friend).UpdateColumn("status", "accepted")
		if result.Error != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update friend request"})
			return
		}

		var friendData map[string]interface{}
		if friend.UserID1 == inputFriend.UserID2 {
			friendData = map[string]interface{}{
				"ID":         friend.ID,
				"FriendID":   friend.UserID2,
				"Status":     friend.Status,
				"UserPseudo": friend.User2.Pseudo,
				"Profile":    friend.User2.Profile,
			}
		} else {
			friendData = map[string]interface{}{
				"ID":         friend.ID,
				"FriendID":   friend.UserID1,
				"Status":     friend.Status,
				"UserPseudo": friend.User1.Pseudo,
				"Profile":    friend.User1.Profile,
			}
		}

		c.JSON(http.StatusOK, friendData)
	}
}

func RefuseFriend() gin.HandlerFunc {
	return func(c *gin.Context) {
		var inputFriend struct {
			ID      uuid.UUID `json:"id"`
			UserID2 uuid.UUID `json:"userId2"`
		}
		if err := c.ShouldBindJSON(&inputFriend); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"message": "Invalide JSON data"})
			return
		}

		var friend models.Friend
		result := db.GetDB().Preload("User1").Preload("User2").First(&friend, inputFriend.ID)
		if result.Error != nil {
			c.JSON(http.StatusNotFound, gin.H{"message": "Demande d'ami non trouvée"})
			return
		}

		if friend.UserID2 != inputFriend.UserID2 {
			c.JSON(http.StatusUnauthorized, gin.H{"message": "Demande d'ami non autorisée"})
			return
		}

		if friend.Status == "refused" {
			c.JSON(http.StatusBadRequest, gin.H{"message": "Demande d'ami déjà refusée"})
			return
		}

		result = db.GetDB().Model(&friend).UpdateColumn("status", "refused")
		if result.Error != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update friend request"})
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "Demande d'ami refusée avec succès"})
	}
}

func SearchUser() gin.HandlerFunc {
	return func(c *gin.Context) {
		pseudo := c.Param("pseudo")
		var users []models.User

		pseudo = strings.ToLower(pseudo)

		result := db.GetDB().Where("LOWER(pseudo) LIKE ?", pseudo+"%").Find(&users)
		if result.Error != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to search users"})
			return
		}

		if len(users) == 0 {
			c.JSON(http.StatusOK, gin.H{"message": "Pas d'utilisateurs trouvés avec ce pseudo"})
			return
		}

		c.JSON(http.StatusOK, users)
	}
}

func GetFriendsByUser() gin.HandlerFunc {
	return func(c *gin.Context) {
		userIDStr := c.Param("id")
		userID, err := uuid.Parse(userIDStr)
		if err != nil {
			handleError(c, http.StatusBadRequest, "ID utilisateur invalide")
			return
		}

		// Vérifier si l'utilisateur existe en base de données
		var user models.User
		if err := db.GetDB().Where("id = ?", userID).First(&user).Error; err != nil {
			handleError(c, http.StatusNotFound, "Utilisateur non trouvé")
			return
		}

		var friends []models.Friend
		result := db.GetDB().Preload("User1").Preload("User2").
			Where("(user_id1 = ? OR user_id2 = ?) AND status = ?", userID, userID, "accepted").Find(&friends)
		if result.Error != nil {
			handleError(c, http.StatusInternalServerError, "Impossible de récupérer les amis")
			return
		}

		friendsResponse := make([]map[string]interface{}, 0)
		for _, friend := range friends {
			var friendPseudo, friendProfile string
			var friendID uuid.UUID

			if friend.UserID1 == userID {
				friendPseudo = friend.User2.Pseudo
				friendID = friend.UserID2
				friendProfile = friend.User2.Profile
			} else {
				friendPseudo = friend.User1.Pseudo
				friendID = friend.UserID1
				friendProfile = friend.User1.Profile
			}

			friendData := map[string]interface{}{
				"ID":         friend.ID,
				"FriendID":   friendID,
				"Status":     friend.Status,
				"UserPseudo": friendPseudo,
				"Profile":    friendProfile,
			}
			friendsResponse = append(friendsResponse, friendData)
		}

		c.JSON(http.StatusOK, friendsResponse)
	}
}

func GetPendingFriendsByUser() gin.HandlerFunc {
	return func(c *gin.Context) {
		userIDStr := c.Param("id")
		userID, err := uuid.Parse(userIDStr)
		if err != nil {
			handleError(c, http.StatusBadRequest, "ID utilisateur invalide")
			return
		}

		var user models.User
		if err := db.GetDB().Where("id = ?", userID).First(&user).Error; err != nil {
			handleError(c, http.StatusNotFound, "Utilisateur non trouvé")
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
				"ID":            friend.ID,
				"FriendID":      userID,
				"FriendUser1ID": friend.User1.ID,
				"Status":        friend.Status,
				"UserPseudo":    friend.User1.Pseudo,
				"Profile":       friend.User1.Profile,
			}
			friendsResponse[i] = friendData
		}

		c.JSON(http.StatusOK, friendsResponse)
	}
}

func GetPendingFriendsFromUser() gin.HandlerFunc {
	return func(c *gin.Context) {
		userIDStr := c.Param("id")
		userID, err := uuid.Parse(userIDStr)
		if err != nil {
			handleError(c, http.StatusBadRequest, "ID utilisateur invalide")
			return
		}

		var user models.User
		if err := db.GetDB().Where("id = ?", userID).First(&user).Error; err != nil {
			handleError(c, http.StatusNotFound, "Utilisateur non trouvé")
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
				"Profile":    friend.User2.Profile,
			}
			friendsResponse[i] = friendData
		}

		c.JSON(http.StatusOK, friendsResponse)
	}
}

func CreateFriendRequest() gin.HandlerFunc {
	return func(c *gin.Context) {
		var input struct {
			UserID     uuid.UUID `json:"userId"`
			UserPseudo string    `json:"userPseudo"`
		}

		if err := c.ShouldBindJSON(&input); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"message": "Invalide JSON data"})
			return
		}

		if input.UserID == uuid.Nil {
			c.JSON(http.StatusBadRequest, gin.H{"message": "Le champ UserID ne peut pas être vide"})
			return
		}

		if input.UserPseudo == "" {
			c.JSON(http.StatusBadRequest, gin.H{"message": "Le champ UserPseudo ne peut pas être vide"})
			return
		}

		var user models.User
		result := db.GetDB().Where("pseudo = ?", input.UserPseudo).First(&user)
		if result.Error != nil {
			c.JSON(http.StatusNotFound, gin.H{"message": "L'utilisateur n'existe pas"})
			return
		}

		if input.UserID == user.ID {
			c.JSON(http.StatusBadRequest, gin.H{"message": "Vous ne pouvez pas vous ajouter en tant qu'ami"})
			return
		}

		var existingFriend models.Friend
		result = db.GetDB().Where("((user_id1 = ? AND user_id2 = ?) OR (user_id1 = ? AND user_id2 = ?)) AND status = 'pending'",
			input.UserID, user.ID, user.ID, input.UserID).First(&existingFriend)

		if result.Error == nil {
			c.JSON(http.StatusConflict, gin.H{"message": "Demande d'ami déjà envoyée"})
			return
		}

		var existingFriendship models.Friend
		result = db.GetDB().Where("((user_id1 = ? AND user_id2 = ?) OR (user_id1 = ? AND user_id2 = ?)) AND status = 'accepted'",
			input.UserID, user.ID, user.ID, input.UserID).First(&existingFriendship)

		if result.Error == nil {
			c.JSON(http.StatusConflict, gin.H{"message": "Vous êtes déjà amis avec cet utilisateur"})
			return
		}

		friend := models.Friend{
			UserID1: input.UserID,
			UserID2: user.ID,
			Status:  "pending",
		}

		result = db.GetDB().Create(&friend)
		if result.Error != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to send friend request"})
			return
		}

		db.GetDB().Preload("User1").Preload("User2").First(&friend)

		c.JSON(http.StatusOK, gin.H{"message": "Demande d'ami envoyée avec succès", "friend": friend})
	}
}
