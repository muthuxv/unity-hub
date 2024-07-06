package services

import (
	"app/db"
	"app/db/models"
	"encoding/json"
	"log"
	"net/http"

	"github.com/google/uuid"
	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
}

func WsHandler(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println(err)
		return
	}
	defer conn.Close()

	log.Println("Web socket called")
	for {
		_, msg, err := conn.ReadMessage()
		if err != nil {
			log.Println(err)
			break
		}

		log.Printf("Received message: %s\n", msg)
		err = conn.WriteMessage(websocket.TextMessage, msg)
		if err != nil {
			log.Println(err)
			break
		}
	}
}

var channelConnections = make(map[uuid.UUID][]*websocket.Conn)

func ChannelWsHandler(w http.ResponseWriter, r *http.Request, channelId string) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println("Upgrade error:", err)
		return
	}
	defer conn.Close()

	channelIDuuid, err := uuid.Parse(channelId)
	if err != nil {
		log.Println("Channel ID conversion error:", err)
		return
	}

	log.Printf("WebSocket connected for channel ID: %d\n", channelIDuuid)

	channelID := uuid.UUID(channelIDuuid)
	channelConnections[channelID] = append(channelConnections[channelID], conn)

	for {
		_, msgBytes, err := conn.ReadMessage()
		if err != nil {
			log.Println("Read message error:", err)
			break
		}

		var receivedMessage map[string]interface{}
		err = json.Unmarshal(msgBytes, &receivedMessage)
		if err != nil {
			log.Println("Error decoding JSON:", err)
			continue
		}

		userID, _ := uuid.Parse(receivedMessage["UserID"].(string))
		messageContent := receivedMessage["Content"].(string)

		log.Printf("Received message on channel %d: %s\n", channelID, messageContent)

		saveMessageToChannel(channelID, receivedMessage, userID)

		var user models.User
		db.GetDB().Where("id = ?", userID).First(&user)
		receivedMessage["User"] = map[string]interface{}{
			"ID":      user.ID,
			"Pseudo":  user.Pseudo,
			"Profile": user.Profile,
		}

		msgBytes, err = json.Marshal(receivedMessage)
		if err != nil {
			log.Println("Error encoding JSON:", err)
			continue
		}

		for _, c := range channelConnections[channelID] {
			err = c.WriteMessage(websocket.TextMessage, msgBytes)
			if err != nil {
				log.Println("Write message error:", err)
				break
			}
		}

		log.Printf("Sent message on channel %d: %s\n", channelID, messageContent)
	}

	connections := channelConnections[channelID]
	for i, c := range connections {
		if c == conn {
			channelConnections[channelID] = append(connections[:i], connections[i+1:]...)
			break
		}
	}
}

func saveMessageToChannel(channelID uuid.UUID, message map[string]interface{}, userID uuid.UUID) {
	newMessage := models.Message{
		Content:   message["Content"].(string),
		Type:      message["Type"].(string),
		ChannelID: channelID,
		UserID:    userID,
		SentAt:    message["SentAt"].(string),
	}

	db.GetDB().Create(&newMessage)
}
