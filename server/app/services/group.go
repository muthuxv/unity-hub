package services

import (
	"app/db"
	"app/db/models"
	"errors"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

func CreateOrGetDM() gin.HandlerFunc {
	return func(c *gin.Context) {
		userID1, err := uuid.Parse(c.Param("userID"))
		if err != nil {
			c.Error(err)
			return
		}

		var input struct {
			UserID2 uuid.UUID `json:"userID"`
		}

		if err := c.ShouldBindJSON(&input); err != nil {
			c.Error(err)
			return
		}

		userID2 := input.UserID2

		if userID1 == userID2 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Cannot create a DM with yourself"})
			return
		}

		var group models.Group
		err = db.GetDB().Where("type = ? AND (id IN (SELECT group_id FROM group_members WHERE user_id = ?) AND id IN (SELECT group_id FROM group_members WHERE user_id = ?))", "dm", userID1, userID2).First(&group).Error
		if err == nil {
			c.JSON(http.StatusOK, group)
			return
		}
		if !errors.Is(err, gorm.ErrRecordNotFound) {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		channel := models.Channel{
			Name:       "Direct Message",
			Type:       "dm",
			Permission: "private",
			ServerID:   uuid.Nil,
		}
		if err := db.GetDB().Create(&channel).Error; err != nil {
			c.Error(err)
			return
		}

		group = models.Group{Type: "dm", ChannelID: channel.ID}
		if err := db.GetDB().Create(&group).Error; err != nil {
			c.Error(err)
			return
		}

		groupMembers := []models.GroupMember{
			{UserID: userID1, GroupID: group.ID},
			{UserID: userID2, GroupID: group.ID},
		}

		for _, gm := range groupMembers {
			if err := db.GetDB().Create(&gm).Error; err != nil {
				c.Error(err)
				return
			}
		}

		c.JSON(http.StatusCreated, group)
	}
}

func CreatePublicGroup() gin.HandlerFunc {
	return func(c *gin.Context) {

		userID, err := uuid.Parse(c.Param("userID"))
		if err != nil {
			c.Error(err)
			return
		}

		var request struct {
			GroupID   uuid.UUID   `json:"group_id"`
			MemberIDs []uuid.UUID `json:"member_ids" binding:"required"`
		}

		if err := c.ShouldBindJSON(&request); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		memberIDs := request.MemberIDs

		var group models.Group
		var channel models.Channel

		if request.GroupID == uuid.Nil {
			var members []models.User
			if err := db.GetDB().Where("id IN (?)", append(memberIDs, userID)).Find(&members).Error; err != nil {
				c.Error(err)
				return
			}

			memberNames := []string{}
			for _, member := range members {
				memberNames = append(memberNames, member.Pseudo)
			}

			channelName := strings.Join(memberNames, ", ")

			channel = models.Channel{
				Name:       channelName,
				Type:       "group",
				Permission: "public",
				ServerID:   uuid.Nil,
			}

			if err := db.GetDB().Create(&channel).Error; err != nil {
				c.Error(err)
				return
			}

			group = models.Group{Type: "group", ChannelID: channel.ID}
			if err := db.GetDB().Create(&group).Error; err != nil {
				c.Error(err)
				return
			}
		} else {
			err = db.GetDB().Preload("Channel").First(&group, request.GroupID).Error
			if err != nil {
				c.Error(err)
				return
			}
			if group.Type != "group" {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid group type"})
				return
			}
			channel = *group.Channel

			//update group name
			var members []models.User
			if err := db.GetDB().Where("id IN (?)", append(memberIDs, userID)).Find(&members).Error; err != nil {
				c.Error(err)
				return
			}

			memberNames := []string{}

			for _, member := range members {
				memberNames = append(memberNames, member.Pseudo)
			}

			channel.Name = strings.Join(memberNames, ", ")

			if err := db.GetDB().Updates(&channel).Error; err != nil {
				c.Error(err)
				return
			}
		}

		groupMembers := []models.GroupMember{
			{UserID: userID, GroupID: group.ID},
		}

		for _, memberID := range memberIDs {
			groupMembers = append(groupMembers, models.GroupMember{UserID: memberID, GroupID: group.ID})
		}

		for _, gm := range groupMembers {
			if err := db.GetDB().Create(&gm).Error; err != nil {
				c.Error(err)
				return
			}
		}

		c.JSON(http.StatusCreated, group)
	}
}

func GetGroupMembers() gin.HandlerFunc {
	return func(c *gin.Context) {
		groupID, err := uuid.Parse(c.Param("groupID"))
		if err != nil {
			c.Error(err)
			return
		}

		var groupMembers []models.GroupMember
		err = db.GetDB().Where("group_id = ?", groupID).Find(&groupMembers).Error
		if err != nil {
			c.Error(err)
			return
		}

		var users []models.User
		for _, gm := range groupMembers {
			var user models.User
			err = db.GetDB().Where("id = ?", gm.UserID).First(&user).Error
			if err != nil {
				c.Error(err)
				return
			}
			user.Email = ""
			user.Password = ""
			user.FcmToken = ""
			users = append(users, user)
		}

		c.JSON(http.StatusOK, users)
	}
}

func RemoveGroupMember() gin.HandlerFunc {
	return func(c *gin.Context) {
		groupID, err := uuid.Parse(c.Param("groupID"))
		if err != nil {
			c.Error(err)
			return
		}

		userID, err := uuid.Parse(c.Param("userID"))
		if err != nil {
			c.Error(err)
			return
		}

		result := db.GetDB().Where("group_id = ? AND user_id = ?", groupID, userID).Delete(&models.GroupMember{})
		if result.Error != nil {
			c.Error(result.Error)
			return
		}

		if result.RowsAffected == 0 {
			c.JSON(http.StatusNotFound, gin.H{"error": "Group member not found"})
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "Group member removed successfully"})
	}
}

func GetUserGroups() gin.HandlerFunc {
	return func(c *gin.Context) {
		userID, err := uuid.Parse(c.Param("userID"))
		if err != nil {
			c.Error(err)
			return
		}

		var groupMembers []models.GroupMember
		err = db.GetDB().Where("user_id = ?", userID).Find(&groupMembers).Error
		if err != nil {
			c.Error(err)
			return
		}

		var groups []models.Group
		for _, gm := range groupMembers {
			var group models.Group
			err = db.GetDB().Preload("Channel").Preload("Members").Where("id = ?", gm.GroupID).First(&group).Error
			if err != nil {
				c.Error(err)
				return
			}
			groups = append(groups, group)
		}

		c.JSON(http.StatusOK, groups)
	}
}
