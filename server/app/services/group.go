package services

import (
	"app/db"
	"app/db/models"
	"errors"
	"log"
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
		log.Println("Creating public group")
		userID, err := uuid.Parse(c.Param("userID"))
		if err != nil {
			c.Error(err)
			return
		}

		log.Println("User ID:", userID)

		var request struct {
			MemberIDs []string `json:"member_ids" binding:"required"`
			GroupID   *string  `json:"group_id"`
		}

		log.Println("Request:", request)

		if err := c.ShouldBindJSON(&request); err != nil {
			c.Error(err)
			return
		}

		log.Println("Request2:", request)

		memberIDs := request.MemberIDs
		memberIDs = append(memberIDs, userID.String())

		//parse memberIDs to uuid
		for i, memberID := range memberIDs {
			uuidMemberID, err := uuid.Parse(memberID)
			if err != nil {
				c.Error(err)
				return
			}

			memberIDs[i] = uuidMemberID.String()
		}

		log.Println("Member IDs:", memberIDs)

		//check for duplicates
		uniqueMemberIDs := []string{}
		for _, memberID := range memberIDs {
			found := false
			for _, uniqueMemberID := range uniqueMemberIDs {
				if memberID == uniqueMemberID {
					found = true
					break
				}
			}
			if !found {
				uniqueMemberIDs = append(uniqueMemberIDs, memberID)
			}
		}

		memberIDs = uniqueMemberIDs

		var group models.Group
		var channel models.Channel

		log.Println("Group ID:", request.GroupID)

		if *request.GroupID == "" {
			log.Println("Creating new group")
			var members []models.User
			if err := db.GetDB().Where("id IN (?)", memberIDs).Find(&members).Error; err != nil {
				c.Error(err)
				return
			}

			memberNames := []string{}
			for _, member := range members {
				memberNames = append(memberNames, member.Pseudo)
			}

			channelName := strings.Join(memberNames, ", ")

			log.Println("Channel name:", channelName)

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

			log.Println("New channel created")

			group = models.Group{Type: "group", ChannelID: channel.ID}
			if err := db.GetDB().Create(&group).Error; err != nil {
				c.Error(err)
				return
			}

			log.Println("New group created")
			// Ajouter les membres au groupe
			for _, memberID := range memberIDs {
				groupMember := models.GroupMember{UserID: uuid.MustParse(memberID), GroupID: group.ID}
				if err := db.GetDB().Create(&groupMember).Error; err != nil {
					c.Error(err)
					return
				}
			}

			log.Println("New group created")

			c.JSON(http.StatusCreated, group)
		} else {
			// Ajout de membres à un groupe existant
			err = db.GetDB().Preload("Channel").First(&group, request.GroupID).Error
			if err != nil {
				c.Error(err)
				return
			}

			if group.Type == "dm" {
				// Vérifiez si le groupe est un DM et si l'utilisateur ajouté n'est pas le même que celui dans le DM
				if len(request.MemberIDs) == 1 {
					var groupMembers []models.GroupMember
					if err := db.GetDB().Where("group_id = ?", group.ID).Find(&groupMembers).Error; err != nil {
						c.Error(err)
						return
					}

					for _, gm := range groupMembers {
						if gm.UserID == uuid.MustParse(request.MemberIDs[0]) {
							c.JSON(http.StatusBadRequest, gin.H{"error": "Cannot add the same user to a DM group"})
							return
						}
					}
				}

				// Si le type de groupe est "dm", créer un nouveau groupe avec les membres existants et les nouveaux membres
				var members []models.User
				if err := db.GetDB().Where("id IN (?)", memberIDs).Find(&members).Error; err != nil {
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

				// Ajouter les membres au nouveau groupe
				for _, memberID := range memberIDs {
					groupMember := models.GroupMember{UserID: uuid.MustParse(memberID), GroupID: group.ID}
					if err := db.GetDB().Create(&groupMember).Error; err != nil {
						c.Error(err)
						return
					}
				}

				c.JSON(http.StatusCreated, group)
			} else {
				// Si le type de groupe est "group", ajouter seulement les nouveaux membres
				var groupMembers []models.GroupMember

				err = db.GetDB().Where("group_id = ?", group.ID).Find(&groupMembers).Error
				if err != nil {
					c.Error(err)
					return
				}

				for _, memberID := range memberIDs {
					found := false
					for _, gm := range groupMembers {
						if gm.UserID == uuid.MustParse(memberID) {
							found = true
							break
						}
					}
					if !found {
						groupMember := models.GroupMember{UserID: uuid.MustParse(memberID), GroupID: group.ID}
						if err := db.GetDB().Create(&groupMember).Error; err != nil {
							c.Error(err)
							return
						}
					}
				}

				c.JSON(http.StatusOK, group)
			}
		}
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
