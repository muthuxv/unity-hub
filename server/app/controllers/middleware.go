package controllers

import (
	"app/db"
	"app/db/models"
	"net/http"
	"gorm.io/gorm"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v4"
	"github.com/google/uuid"
)

func ErrorHandling() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Next()

		if len(c.Errors) > 0 {
			err := c.Errors.Last().Err
			switch err.(type) {
			case *gin.Error:
				c.JSON(http.StatusInternalServerError, gin.H{"Muthu error": err.Error()})
			default:
				c.JSON(http.StatusInternalServerError, gin.H{"Muthu error": "Une erreur inconnue est survenue"})
			}
			c.Abort()
		}
	}
}

func GenerateLogMiddleware(action string) gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Next()

		serverIDStr := c.Param("id")
		_, err := uuid.Parse(serverIDStr)
		if err != nil {
			return
		}

		serverID := uuid.MustParse(serverIDStr)

		claims, exists := c.Get("jwt_claims")
		if !exists {
			return
		}

		jwtClaims, ok := claims.(jwt.MapClaims)
		if !ok {
			return
		}

		userPseudo, ok := jwtClaims["pseudo"].(string)
		if !ok {
			return
		}

		logEntry := models.Logs{
			Message:  "User " + userPseudo + " " + action + " server",
			ServerID: serverID,
		}

		db.GetDB().Create(&logEntry)
	}
}

func GenerateLogBanMiddlaware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Next()

		serverIDStr := c.Param("id")
		_, err := uuid.Parse(serverIDStr)
		if err != nil {
			return
		}

		serverID := uuid.MustParse(serverIDStr)

		claims, exists := c.Get("jwt_claims")
		if !exists {
			return
		}

		jwtClaims, ok := claims.(jwt.MapClaims)
		if !ok {
			return
		}

		userIDStr, ok := jwtClaims["jti"].(string)
		if !ok {
			return
		}

		userPseudo, ok := jwtClaims["pseudo"].(string)
		if !ok {
			return
		}

		userID := c.Param("userID")
		if userID == "" {
			return
		}

		_, err = uuid.Parse(userIDStr)
		if err != nil {
			return
		}

		var user models.User
		if err := db.GetDB().Where("id = ?", userID).First(&user).Error; err != nil {
			c.Error(err)
			return
		}

		logEntry := models.Logs{
			Message:  "User " + userPseudo + " banned user " + user.Pseudo + " from server",
			ServerID: serverID,
		}

		db.GetDB().Create(&logEntry)
	}
}

func GenerateLogChannelMiddlaware(action string) gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Next()

		serverIDStr := c.Param("id")
		_, err := uuid.Parse(serverIDStr)
		if err != nil {
			return
		}

		serverID := uuid.MustParse(serverIDStr)

		claims, exists := c.Get("jwt_claims")
		if !exists {
			return
		}

		jwtClaims, ok := claims.(jwt.MapClaims)
		if !ok {
			return
		}

		userIDStr, ok := jwtClaims["jti"].(string)
		if !ok {
			return
		}

		_, err = uuid.Parse(userIDStr)
		if err != nil {
			return
		}

		logEntry := models.Logs{
			Message:  "User " + userIDStr + " " + action + " a channel",
			ServerID: serverID,
		}

		db.GetDB().Create(&logEntry)
	}
}

func IsFriendMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		friendIDStr := c.Param("id")
		friendID, err := uuid.Parse(friendIDStr)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid friendship ID"})
			c.Abort()
			return
		}

		claims, exists := c.Get("jwt_claims")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Missing JWT claims"})
			c.Abort()
			return
		}

		jwtClaims, ok := claims.(jwt.MapClaims)
		if !ok {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid JWT claims"})
			c.Abort()
			return
		}

		userIDStr, ok := jwtClaims["jti"].(string)
		if !ok {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid user ID in token"})
			c.Abort()
			return
		}

		userID, err := uuid.Parse(userIDStr)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid user ID"})
			c.Abort()
			return
		}

		var friend models.Friend
		if err := db.GetDB().Where("id = ?", friendID).First(&friend).Error; err != nil {
			if err == gorm.ErrRecordNotFound {
				c.JSON(http.StatusNotFound, gin.H{"error": "Friendship not found"})
			} else {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
			}
			c.Abort()
			return
		}

		if friend.UserID1 != userID && friend.UserID2 != userID {
			c.JSON(http.StatusForbidden, gin.H{"error": "You are not authorized to modify this friendship"})
			c.Abort()
			return
		}

		c.Next()
	}
}

func IsGroupMemberMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		groupIDStr := c.Param("id")
		groupID, err := uuid.Parse(groupIDStr)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid group ID"})
			c.Abort()
			return
		}

		claims, exists := c.Get("jwt_claims")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Missing JWT claims"})
			c.Abort()
			return
		}

		jwtClaims, ok := claims.(jwt.MapClaims)
		if !ok {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid JWT claims"})
			c.Abort()
			return
		}

		userIDStr, ok := jwtClaims["jti"].(string)
		if !ok {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid user ID in token"})
			c.Abort()
			return
		}

		userID, err := uuid.Parse(userIDStr)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid user ID"})
			c.Abort()
			return
		}

		var groupMember models.GroupMember
		if err := db.GetDB().Where("group_id = ? AND user_id = ?", groupID, userID).First(&groupMember).Error; err != nil {
			c.JSON(http.StatusForbidden, gin.H{"error": "You are not a member of this group"})
			c.Abort()
			return
		}

		c.Next()
	}
}

func IsGroupOwnerMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		groupIDStr := c.Param("id")
		groupID, err := uuid.Parse(groupIDStr)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid group ID"})
			c.Abort()
			return
		}

		claims, exists := c.Get("jwt_claims")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Missing JWT claims"})
			c.Abort()
			return
		}

		jwtClaims, ok := claims.(jwt.MapClaims)
		if !ok {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid JWT claims"})
			c.Abort()
			return
		}

		userIDStr, ok := jwtClaims["jti"].(string)
		if !ok {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid user ID in token"})
			c.Abort()
			return
		}

		userID, err := uuid.Parse(userIDStr)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid user ID"})
			c.Abort()
			return
		}

		var group models.Group
		if err := db.GetDB().Where("id = ? AND owner_id = ?", groupID, userID).First(&group).Error; err != nil {
			c.JSON(http.StatusForbidden, gin.H{"error": "You are not the owner of this group"})
			c.Abort()
			return
		}

		c.Next()
	}
}

func IsUserInInvitationMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		invitationIDStr := c.Param("id")
		invitationID, err := uuid.Parse(invitationIDStr)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid invitation ID"})
			c.Abort()
			return
		}

		claims, exists := c.Get("jwt_claims")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Missing JWT claims"})
			c.Abort()
			return
		}

		jwtClaims, ok := claims.(jwt.MapClaims)
		if !ok {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid JWT claims"})
			c.Abort()
			return
		}

		userIDStr, ok := jwtClaims["jti"].(string)
		if !ok {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid user ID in token"})
			c.Abort()
			return
		}

		userID, err := uuid.Parse(userIDStr)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid user ID"})
			c.Abort()
			return
		}

		var invitation models.Invitation
		if err := db.GetDB().Where("id = ? AND (user_sender_id = ? OR user_receiver_id = ?)", invitationID, userID, userID).First(&invitation).Error; err != nil {
			c.JSON(http.StatusForbidden, gin.H{"error": "You are not authorized to modify this invitation"})
			c.Abort()
			return
		}

		c.Next()
	}
}

func IsUserOnServerMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		serverIDStr := c.Param("id")
		serverID, err := uuid.Parse(serverIDStr)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid server ID"})
			c.Abort()
			return
		}

		claims, exists := c.Get("jwt_claims")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Missing JWT claims"})
			c.Abort()
			return
		}

		jwtClaims, ok := claims.(jwt.MapClaims)
		if !ok {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid JWT claims"})
			c.Abort()
			return
		}

		userIDStr, ok := jwtClaims["jti"].(string)
		if !ok {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid user ID in token"})
			c.Abort()
			return
		}

		userID, err := uuid.Parse(userIDStr)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid user ID"})
			c.Abort()
			return
		}

		var onServer models.OnServer
		if err := db.GetDB().Where("server_id = ? AND user_id = ?", serverID, userID).First(&onServer).Error; err != nil {
			c.JSON(http.StatusForbidden, gin.H{"error": "You are not authorized to access this server"})
			c.Abort()
			return
		}

		c.Next()
	}
}