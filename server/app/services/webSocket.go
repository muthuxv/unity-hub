package services

import (
	"app/db"
	"app/db/models"
	"encoding/json"
	"log"
	"net/http"
	"strconv"

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

func ChannelWsHandler(w http.ResponseWriter, r *http.Request, channelId string) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println("Upgrade error:", err)
		return
	}
	defer conn.Close()

	channelIDUint, err := strconv.ParseUint(channelId, 10, 32)
	if err != nil {
		log.Println("Channel ID conversion error:", err)
		return
	}

	log.Printf("WebSocket connected for channel ID: %d\n", channelIDUint)

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

		userID, _ := strconv.ParseUint(receivedMessage["userID"].(string), 10, 64)
		messageContent := receivedMessage["Content"].(string)

		log.Printf("Received message on channel %d: %s\n", channelIDUint, messageContent)

		saveMessageToChannel(uint(channelIDUint), messageContent, uint(userID))

		err = conn.WriteMessage(websocket.TextMessage, msgBytes)
		if err != nil {
			log.Println("Write message error:", err)
			break
		}
	}
}

func saveMessageToChannel(channelID uint, messageContent string, userID uint) {
	newMessage := models.Message{
		Content:   messageContent,
		ChannelID: channelID,
		UserID:    userID,
	}

	db.GetDB().Create(&newMessage)
}
