package services

import (
	"app/db"
	"app/db/models"
	"encoding/json"
	"log"
	"net/http"

	"github.com/google/uuid"
	"github.com/gorilla/websocket"
	"github.com/julienschmidt/httprouter"
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

type WebSocketMessage struct {
	Type    string      `json:"type"`
	Channel interface{} `json:"channel,omitempty"`
}

type Channel struct {
	ID         int    `json:"ID,omitempty"`
	Name       string `json:"Name"`
	Type       string `json:"Type"`
	Permission string `json:"Permission"`
	ServerID   uint   `json:"ServerID"`
}

type Server struct {
	ID        int
	Clients   map[*websocket.Conn]bool
	Broadcast chan WebSocketMessage
}

var servers = make(map[int]*Server)

func ServerWsHandler(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
	serverID, err := strconv.Atoi(ps.ByName("id"))
	if err != nil {
		log.Println("Invalid server ID:", err)
		return
	}

	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println("Error upgrading to WebSocket:", err)
		return
	}

	if _, ok := servers[serverID]; !ok {
		servers[serverID] = &Server{
			ID:        serverID,
			Clients:   make(map[*websocket.Conn]bool),
			Broadcast: make(chan WebSocketMessage),
		}
		go handleMessages(serverID)
	}

	servers[serverID].Clients[conn] = true
	log.Println("Clients connected to server:", servers[serverID].Clients)

	log.Printf("Client connected to server %d\n", serverID)
	log.Printf("Number of clients connected to server %d: %d\n", serverID, len(servers[serverID].Clients))
	log.Printf("Number of servers: %d\n", len(servers))
	log.Printf("Server IDs: %v\n", servers)

	defer func() {
		conn.Close()
		delete(servers[serverID].Clients, conn)
	}()

	for {
		_, msgBytes, err := conn.ReadMessage()
		if err != nil {
			log.Println("Error reading message:", err)
			break
		}

		var receivedMessage map[string]interface{}
		err = json.Unmarshal(msgBytes, &receivedMessage)
		if err != nil {
			log.Println("Error decoding JSON:", err)
			continue
		}
	}
}

func handleMessages(serverID int) {
	for {
		message := <-servers[serverID].Broadcast

		for client := range servers[serverID].Clients {
			err := client.WriteJSON(message)
			if err != nil {
				log.Println("Error writing JSON:", err)
				client.Close()
				delete(servers[serverID].Clients, client)
			}
		}
	}
}

func AddChannelHandler(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
	serverID, err := strconv.Atoi(ps.ByName("id"))
	if err != nil {
		http.Error(w, "Invalid server ID", http.StatusBadRequest)
		return
	}

	serverIDUint := uint(serverID)

	var channel Channel
	if err := json.NewDecoder(r.Body).Decode(&channel); err != nil {
		http.Error(w, "Invalid request payload", http.StatusBadRequest)
		return
	}

	// Create the channel in the database
	newChannel := models.Channel{
		Name:       channel.Name,
		Type:       channel.Type,
		Permission: channel.Permission,
		ServerID:   serverIDUint,
	}

	if err := db.GetDB().Create(&newChannel).Error; err != nil {
		http.Error(w, "Error creating channel", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(newChannel)

	log.Printf("Channel created on server %d with ID %d\n", serverID, newChannel.ID)
}
