package services

import (
	"app/db"
	"app/db/models"
	"encoding/json"
	"log"
	"net/http"
	"os"

	"github.com/golang-jwt/jwt/v4"

	"github.com/google/uuid"
	"github.com/gorilla/websocket"
	"github.com/julienschmidt/httprouter"
)

var jwtKey = []byte(os.Getenv("JWT_KEY"))

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

func verifyWebSocketPermission(userID uuid.UUID, channelID uuid.UUID, requiredPermission string, serverID uuid.UUID) (bool, error) {
	var roleUser models.RoleUser
	if err := db.GetDB().Joins("JOIN roles ON roles.id = role_users.role_id").Where("role_users.user_id = ? AND roles.server_id = ?", userID, serverID).First(&roleUser).Error; err != nil {
		return false, err
	}

	var rolePermissions []models.RolePermissions
	if err := db.GetDB().Where("role_id = ?", roleUser.RoleID).Preload("Permissions").Find(&rolePermissions).Error; err != nil {
		return false, err
	}

	var channelPermissions models.ChannelChannelPermissions
	if err := db.GetDB().Joins("JOIN channel_permissions ON channel_permissions.id = channel_channel_permissions.channel_permission_id").
		Where("channel_channel_permissions.channel_id = ? AND channel_permissions.label = ?", channelID, requiredPermission).
		First(&channelPermissions).Error; err != nil {
		return false, err
	}

	for _, rp := range rolePermissions {
		log.Println(rp.Permissions.Label)
		log.Println(requiredPermission)
		log.Println(rp.Power)
		log.Println(channelPermissions.Power)
		if rp.Permissions.Label == requiredPermission && rp.Power >= channelPermissions.Power {
			return true, nil
		}
	}

	return false, nil
}

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

    log.Printf("WebSocket connected for channel ID: %s\n", channelIDuuid)

    reqToken := r.URL.Query().Get("token")
    if reqToken == "" {
        log.Println("Missing token")
        return
    }

    token, err := jwt.Parse(reqToken, func(token *jwt.Token) (interface{}, error) {
        if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
            return nil, http.ErrNotSupported
        }
        return jwtKey, nil
    })

    if err != nil || !token.Valid {
        log.Println("Invalid token")
        return
    }

    claims, ok := token.Claims.(jwt.MapClaims)
    if !ok || !token.Valid {
        log.Println("Invalid token claims")
        return
    }

    userIDStr, ok := claims["jti"].(string)
    if !ok {
        log.Println("Invalid token claims")
        return
    }

    userID, err := uuid.Parse(userIDStr)
    if err != nil {
        log.Println("Invalid user ID")
        return
    }

    var channel models.Channel
    if err := db.GetDB().Where("id = ?", channelIDuuid).First(&channel).Error; err != nil {
        log.Println("Channel not found")
        return
    }

    var canSendMessage bool
    if channel.ServerID != uuid.Nil {
        canSendMessage, err = verifyWebSocketPermission(userID, channelIDuuid, "sendMessage", channel.ServerID)
        if err != nil {
            log.Println("Error verifying permissions:", err)
            canSendMessage = false
        }
    }

    channelConnections[channelIDuuid] = append(channelConnections[channelIDuuid], conn)

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

        log.Printf("Received message on channel %s: %s\n", channelIDuuid, messageContent)

        if canSendMessage {
            saveMessageToChannel(channelIDuuid, receivedMessage, userID)
        } else {
            log.Println("User does not have permission to send messages on this channel")
            receivedMessage["Content"] = "User does not have permission to send messages"
        }

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

        for _, c := range channelConnections[channelIDuuid] {
            err = c.WriteMessage(websocket.TextMessage, msgBytes)
            if err != nil {
                log.Println("Write message error:", err)
                break
            }
        }

        log.Printf("Sent message on channel %s: %s\n", channelIDuuid, messageContent)
    }

    connections := channelConnections[channelIDuuid]
    for i, c := range connections {
        if c == conn {
            channelConnections[channelIDuuid] = append(connections[:i], connections[i+1:]...)
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
	ID       int    `json:"ID,omitempty"`
	Name     string `json:"Name"`
	Type     string `json:"Type"`
	ServerID uint   `json:"ServerID"`
}

type Server struct {
	ID        uuid.UUID
	Clients   map[*websocket.Conn]bool
	Broadcast chan WebSocketMessage
}

var servers = make(map[uuid.UUID]*Server)

func ServerWsHandler(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
	serverID, err := uuid.Parse(ps.ByName("id"))
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

func handleMessages(serverID uuid.UUID) {
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
	serverID, err := uuid.Parse(ps.ByName("id"))
	if err != nil {
		http.Error(w, "Invalid server ID", http.StatusBadRequest)
		return
	}

	serverIDU := uuid.UUID(serverID)

	var channel Channel
	if err := json.NewDecoder(r.Body).Decode(&channel); err != nil {
		http.Error(w, "Invalid request payload", http.StatusBadRequest)
		return
	}

	// Create the channel in the database
	newChannel := models.Channel{
		Name:     channel.Name,
		Type:     channel.Type,
		ServerID: serverIDU,
	}

	servers[serverIDU].Broadcast <- WebSocketMessage{
		Type: "new_channel",
		Channel: map[string]interface{}{
			"ID":       newChannel.ID,
			"Name":     newChannel.Name,
			"Type":     newChannel.Type,
			"ServerID": newChannel.ServerID,
		},
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
