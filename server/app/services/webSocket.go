package services

import (
	"github.com/gorilla/websocket"
	"net/http"
	"log"
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