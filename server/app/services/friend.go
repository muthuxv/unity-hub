package services

import (
	"app/db"
	"app/db/models"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// AcceptFriend godoc
// @Summary Accept a friend request
// @Description Accept a friend request
// @Tags friends
// @Accept json
// @Produce json
// @Param friendRequest body models.FriendRequest true "Friend request data"
// @Success 200 {object} models.FriendResponse
// @Failure 400 {object} models.ErrorResponse
// @Failure 404 {object} models.ErrorResponse
// @Failure 401 {object} models.ErrorResponse
// @Router /friends/accept [put]
func AcceptFriend() gin.HandlerFunc {
	return func(c *gin.Context) {
		var inputFriend struct {
			ID      uuid.UUID `json:"id"`
			UserID2 uuid.UUID `json:"userId2"`
		}
		if err := c.ShouldBindJSON(&inputFriend); err != nil {
			c.JSON(http.StatusBadRequest, models.ErrorResponse{Error: "Invalide JSON data"})
			return
		}

		var friend models.Friend
		result := db.GetDB().Where("id = ?", inputFriend.ID).Preload("User1").Preload("User2").First(&friend)
		if result.Error != nil {
			c.JSON(http.StatusNotFound, models.ErrorResponse{Error: "Demande d'ami non trouvée"})
			return
		}

		if friend.UserID2 != inputFriend.UserID2 {
			c.JSON(http.StatusUnauthorized, models.ErrorResponse{Error: "Demande d'ami non autorisée"})
			return
		}

		if friend.Status == "accepted" {
			c.JSON(http.StatusBadRequest, models.ErrorResponse{Error: "Demande d'ami déjà acceptée"})
			return
		}

		result = db.GetDB().Model(&friend).UpdateColumn("status", "accepted")
		if result.Error != nil {
			c.JSON(http.StatusInternalServerError, models.ErrorResponse{Error: "Failed to update friend request"})
			return
		}

		var friendData models.FriendResponse
		if friend.UserID1 == inputFriend.UserID2 {
			friendData = models.FriendResponse{
				ID:         friend.ID,
				FriendID:   friend.UserID2,
				Status:     friend.Status,
				UserPseudo: friend.User2.Pseudo,
				UserMail:   friend.User2.Email,
				Profile:    friend.User2.Profile,
			}
		} else {
			friendData = models.FriendResponse{
				ID:         friend.ID,
				FriendID:   friend.UserID1,
				Status:     friend.Status,
				UserPseudo: friend.User1.Pseudo,
				UserMail:   friend.User1.Email,
				Profile:    friend.User1.Profile,
			}
		}

		c.JSON(http.StatusOK, friendData)
	}
}

// RefuseFriend godoc
// @Summary Refuse a friend request
// @Description Refuse a friend request
// @Tags friends
// @Accept json
// @Produce json
// @Param friendRequest body models.FriendRequest true "Friend request data"
// @Success 200 {object} models.SuccessResponse
// @Failure 400 {object} models.ErrorResponse
// @Failure 404 {object} models.ErrorResponse
// @Failure 401 {object} models.ErrorResponse
// @Router /friends/refuse [put]
func RefuseFriend() gin.HandlerFunc {
	return func(c *gin.Context) {
		var inputFriend struct {
			ID      uuid.UUID `json:"id"`
			UserID2 uuid.UUID `json:"userId2"`
		}
		if err := c.ShouldBindJSON(&inputFriend); err != nil {
			c.JSON(http.StatusBadRequest, models.ErrorResponse{Error: "Invalide JSON data"})
			return
		}

		var friend models.Friend
		result := db.GetDB().Preload("User1").Preload("User2").First(&friend, inputFriend.ID)
		if result.Error != nil {
			c.JSON(http.StatusNotFound, models.ErrorResponse{Error: "Demande d'ami non trouvée"})
			return
		}

		if friend.UserID2 != inputFriend.UserID2 {
			c.JSON(http.StatusUnauthorized, models.ErrorResponse{Error: "Demande d'ami non autorisée"})
			return
		}

		if friend.Status == "refused" {
			c.JSON(http.StatusBadRequest, models.ErrorResponse{Error: "Demande d'ami déjà refusée"})
			return
		}

		result = db.GetDB().Model(&friend).UpdateColumn("status", "refused")
		if result.Error != nil {
			c.JSON(http.StatusInternalServerError, models.ErrorResponse{Error: "Failed to update friend request"})
			return
		}

		c.JSON(http.StatusOK, models.SuccessResponse{Message: "Demande d'ami refusée avec succès"})
	}
}

// SearchUser godoc
// @Summary Search for users by pseudo
// @Description Search for users by pseudo
// @Tags friends
// @Produce json
// @Param pseudo path string true "User Pseudo"
// @Success 200 {array} models.SearchUserResponse
// @Failure 400 {object} models.ErrorResponse
// @Failure 404 {object} models.ErrorResponse
// @Router /friends/search/{pseudo} [get]
func SearchUser() gin.HandlerFunc {
	return func(c *gin.Context) {
		pseudo := c.Param("pseudo")
		var users []models.User

		pseudo = strings.ToLower(pseudo)

		result := db.GetDB().Where("LOWER(pseudo) LIKE ?", pseudo+"%").Find(&users)
		if result.Error != nil {
			c.JSON(http.StatusInternalServerError, models.ErrorResponse{Error: "Failed to search users"})
			return
		}

		if len(users) == 0 {
			c.JSON(http.StatusOK, models.ErrorResponse{Error: "Pas d'utilisateurs trouvés avec ce pseudo"})
			return
		}

		c.JSON(http.StatusOK, users)
	}
}

// GetFriendsByUser godoc
// @Summary Get friends by user ID
// @Description Get friends by user ID
// @Tags friends
// @Produce json
// @Param id path string true "User ID"
// @Success 200 {array} models.FriendResponse
// @Failure 400 {object} models.ErrorResponse
// @Failure 404 {object} models.ErrorResponse
// @Router /friends/user/{id} [get]
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

		friendsResponse := make([]models.FriendResponse, 0)
		for _, friend := range friends {
			var friendPseudo, friendEmail, friendProfile string
			var friendID uuid.UUID

			if friend.UserID1 == userID {
				friendPseudo = friend.User2.Pseudo
				friendEmail = friend.User2.Email
				friendID = friend.UserID2
				friendProfile = friend.User2.Profile
			} else {
				friendPseudo = friend.User1.Pseudo
				friendEmail = friend.User1.Email
				friendID = friend.UserID1
				friendProfile = friend.User1.Profile
			}

			friendData := models.FriendResponse{
				ID:         friend.ID,
				FriendID:   friendID,
				Status:     friend.Status,
				UserPseudo: friendPseudo,
				UserMail:   friendEmail,
				Profile:    friendProfile,
			}
			friendsResponse = append(friendsResponse, friendData)
		}

		c.JSON(http.StatusOK, friendsResponse)
	}
}

// GetPendingFriendsByUser godoc
// @Summary Get pending friend requests by user ID
// @Description Get pending friend requests by user ID
// @Tags friends
// @Produce json
// @Param id path string true "User ID"
// @Success 200 {array} models.FriendResponse
// @Failure 400 {object} models.ErrorResponse
// @Failure 404 {object} models.ErrorResponse
// @Router /friends/pending/{id} [get]
func GetPendingFriendsByUser() gin.HandlerFunc {
	return func(c *gin.Context) {
		userIDStr := c.Param("id")
		userID, err := uuid.Parse(userIDStr)
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

		friendsResponse := make([]models.FriendResponse, len(friends))
		for i, friend := range friends {

			friendData := models.FriendResponse{
				ID:         friend.ID,
				FriendID:   userID,
				UserPseudo: friend.User1.Pseudo,
				UserMail:   friend.User1.Email,
				Profile:    friend.User1.Profile,
				Status:     friend.Status,
			}
			friendsResponse[i] = friendData
		}

		c.JSON(http.StatusOK, friendsResponse)
	}
}

// GetPendingFriendsFromUser godoc
// @Summary Get pending friend requests sent by user ID
// @Description Get pending friend requests sent by user ID
// @Tags friends
// @Produce json
// @Param id path string true "User ID"
// @Success 200 {array} models.FriendResponse
// @Failure 400 {object} models.ErrorResponse
// @Failure 404 {object} models.ErrorResponse
// @Router /friends/pending/from/{id} [get]
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

		friendsResponse := make([]models.FriendResponse, len(friends))
		for i, friend := range friends {
			friendData := models.FriendResponse{
				ID:         friend.ID,
				FriendID:   friend.UserID2,
				Status:     friend.Status,
				UserPseudo: friend.User2.Pseudo,
				UserMail:   friend.User2.Email,
				Profile:    friend.User2.Profile,
			}
			friendsResponse[i] = friendData
		}

		c.JSON(http.StatusOK, friendsResponse)
	}
}

// CreateFriendRequest godoc
// @Summary Create a friend request
// @Description Create a friend request
// @Tags friends
// @Accept json
// @Produce json
// @Param friendRequest body models.FriendRequest true "Friend request data"
// @Success 200 {object} models.SuccessResponse
// @Failure 400 {object} models.ErrorResponse
// @Failure 404 {object} models.ErrorResponse
// @Failure 409 {object} models.ErrorResponse
// @Router /friends/request [post]
func CreateFriendRequest() gin.HandlerFunc {
	return func(c *gin.Context) {
		var input struct {
			UserID     uuid.UUID `json:"userId"`
			UserPseudo string    `json:"userPseudo"`
		}

		if err := c.ShouldBindJSON(&input); err != nil {
			c.JSON(http.StatusBadRequest, models.ErrorResponse{Error: "Invalide JSON data"})
			return
		}

		var user models.User
		result := db.GetDB().Where("pseudo = ?", input.UserPseudo).First(&user)
		if result.Error != nil {
			c.JSON(http.StatusNotFound, models.ErrorResponse{Error: "L'utilisateur n'existe pas"})
			return
		}

		if input.UserID == user.ID {
			c.JSON(http.StatusBadRequest, models.ErrorResponse{Error: "Vous ne pouvez pas vous ajouter en tant qu'ami"})
			return
		}

		var existingFriend models.Friend
		result = db.GetDB().Where("((user_id1 = ? AND user_id2 = ?) OR (user_id1 = ? AND user_id2 = ?)) AND status = 'pending'",
			input.UserID, user.ID, user.ID, input.UserID).First(&existingFriend)

		if result.Error == nil {
			c.JSON(http.StatusConflict, models.ErrorResponse{Error: "Demande d'ami déjà envoyée"})
			return
		}

		var existingFriendship models.Friend
		result = db.GetDB().Where("((user_id1 = ? AND user_id2 = ?) OR (user_id1 = ? AND user_id2 = ?)) AND status = 'accepted'",
			input.UserID, user.ID, user.ID, input.UserID).First(&existingFriendship)

		if result.Error == nil {
			c.JSON(http.StatusConflict, models.ErrorResponse{Error: "Vous êtes déjà amis avec cet utilisateur"})
			return
		}

		friend := models.Friend{
			UserID1: input.UserID,
			UserID2: user.ID,
			Status:  "pending",
		}

		result = db.GetDB().Create(&friend)
		if result.Error != nil {
			c.JSON(http.StatusInternalServerError, models.ErrorResponse{Error: "Failed to send friend request"})
			return
		}

		db.GetDB().Preload("User1").Preload("User2").First(&friend)

		c.JSON(http.StatusOK, models.SuccessResponse{Message: "Demande d'ami envoyée avec succès"})
	}
}
