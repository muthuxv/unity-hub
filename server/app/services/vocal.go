package services

import (
    "github.com/gin-gonic/gin"
    "github.com/pion/webrtc/v3"
    "net/http"
    "log"
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
        "offer": offer.SDP,
        "channelId": channelId,
    })
}
