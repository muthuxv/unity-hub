package services

import (
	"github.com/gorilla/websocket"
	"net/http"
	"log"
	"app/db/models"
	"app/db"
	"strconv"
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
        _, msg, err := conn.ReadMessage()
        if err != nil {
            log.Println("Read message error:", err)
            break
        }
        
        log.Printf("Received message on channel %d: %s\n", channelIDUint, msg)
        
        saveMessageToChannel(uint(channelIDUint), string(msg))

        err = conn.WriteMessage(websocket.TextMessage, msg)
        if err != nil {
            log.Println("Write message error:", err)
            break
        }
    }
}

func saveMessageToChannel(channelID uint, messageContent string) {
    newMessage := models.Message{
        Content:   messageContent,
        ChannelID: channelID,
        UserID: 1, 
    }
	
	db.GetDB().Create(&newMessage)
}