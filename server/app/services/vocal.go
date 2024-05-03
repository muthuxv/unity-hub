package services

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/pion/webrtc/v3"
)

func ConnectToChannel(c *gin.Context) {
	channelId := c.Param("id")

	peerConnection, err := webrtc.NewPeerConnection(webrtc.Configuration{})
	if err != nil {
		log.Println("Failed to create peer connection:", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create peer connection"})
		return
	}

	peerConnection.OnICECandidate(func(candidate *webrtc.ICECandidate) {
		if candidate != nil {
			log.Printf("New ICE candidate: %s\n", candidate.ToJSON().Candidate)
		}
	})

	offer, err := peerConnection.CreateOffer(nil)
	if err != nil {
		log.Println("Failed to create offer:", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create offer"})
		return
	}

	if err := peerConnection.SetLocalDescription(offer); err != nil {
		log.Println("Failed to set local description:", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to set local description"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"offer":     offer.SDP,
		"channelId": channelId,
	})
}

func HandleAnswer(c *gin.Context) {
	channelId := c.Param("id")
	var answer map[string]interface{}
	if err := c.BindJSON(&answer); err != nil {
		log.Println("Failed to bind answer:", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to bind answer"})
		return
	}

	peerConnection, err := webrtc.NewPeerConnection(webrtc.Configuration{})
	if err != nil {
		log.Println("Failed to create peer connection:", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create peer connection"})
		return
	}

	answerSDP, ok := answer["answer"].(string)
	log.Println(answerSDP)
	if !ok {
		log.Println("Failed to get answer SDP")
		c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to get answer SDP"})
		return
	}

	if err := peerConnection.SetRemoteDescription(webrtc.SessionDescription{Type: webrtc.SDPTypeAnswer, SDP: answerSDP}); err != nil {
		log.Println("Failed to set remote description:", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to set remote description"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"channelId": channelId})
}
