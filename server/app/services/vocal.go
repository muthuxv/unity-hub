package services

import (
    "encoding/json"
    "net/http"
    "sync"
    "log"

    "github.com/pion/webrtc/v3"
)

var (
    peerConnections = make(map[string]*webrtc.PeerConnection)
    userInfo        = make(map[string]map[string]string) // ChannelID -> UserID -> UserInfo
    mutex           sync.Mutex
)

type UserMessage struct {
    Type      string `json:"type"`
    UserID    string `json:"userId"`
    UserName  string `json:"userName"`
    Profile   string `json:"profile"`
    ChannelID string `json:"channelId"`
}

func SDPHandler(w http.ResponseWriter, r *http.Request) {
    var offer struct {
        webrtc.SessionDescription
        ChannelID string `json:"channel_id"`
        UserID    string `json:"user_id"`
        UserName  string `json:"user_name"`
        Profile   string `json:"profile"`
    }
    if err := json.NewDecoder(r.Body).Decode(&offer); err != nil {
        http.Error(w, "Failed to parse offer", http.StatusBadRequest)
        return
    }
    log.Printf("Received SDP offer for channel: %s", offer.ChannelID)

    peerConnection, err := webrtc.NewPeerConnection(webrtc.Configuration{})
    if err != nil {
        http.Error(w, "Failed to create peer connection", http.StatusInternalServerError)
        return
    }
    log.Printf("Created new PeerConnection for channel: %s", offer.ChannelID)

    mutex.Lock()
    peerConnections[offer.ChannelID] = peerConnection
    if userInfo[offer.ChannelID] == nil {
        userInfo[offer.ChannelID] = make(map[string]string)
    }
    userInfo[offer.ChannelID][offer.UserID] = offer.UserName + ";" + offer.Profile
    mutex.Unlock()

    peerConnection.OnICECandidate(func(candidate *webrtc.ICECandidate) {
        if candidate == nil {
            return
        }
        log.Printf("New ICE candidate for channel: %s", offer.ChannelID)

        mutex.Lock()
        defer mutex.Unlock()
        for id, pc := range peerConnections {
            if id != offer.ChannelID {
                _ = pc.AddICECandidate(candidate.ToJSON())
            }
        }
    })

    peerConnection.OnTrack(func(track *webrtc.TrackRemote, receiver *webrtc.RTPReceiver) {
        log.Printf("New track received for channel: %s", offer.ChannelID)
        for id, pc := range peerConnections {
            if id != offer.ChannelID {
                localTrack, err := webrtc.NewTrackLocalStaticRTP(track.Codec().RTPCodecCapability, track.ID(), track.StreamID())
                if err != nil {
                    return
                }
                if _, err = pc.AddTrack(localTrack); err != nil {
                    return
                }
            }
        }
    })

    if err := peerConnection.SetRemoteDescription(offer.SessionDescription); err != nil {
        http.Error(w, "Failed to set remote description", http.StatusInternalServerError)
        return
    }
    log.Printf("Set remote description for channel: %s", offer.ChannelID)

    answer, err := peerConnection.CreateAnswer(nil)
    if err != nil {
        http.Error(w, "Failed to create answer", http.StatusInternalServerError)
        return
    }

    if err := peerConnection.SetLocalDescription(answer); err != nil {
        http.Error(w, "Failed to set local description", http.StatusInternalServerError)
        return
    }
    log.Printf("Set local description and sending answer for channel: %s", offer.ChannelID)

    json.NewEncoder(w).Encode(answer)

    // Notify other users about the new user
    notifyUsers(offer.ChannelID, UserMessage{
        Type:      "join",
        UserID:    offer.UserID,
        UserName:  offer.UserName,
        Profile:   offer.Profile,
        ChannelID: offer.ChannelID,
    })
}

func ICECandidateHandler(w http.ResponseWriter, r *http.Request) {
    var candidate struct {
        webrtc.ICECandidateInit
        ChannelID string `json:"channel_id"`
    }
    if err := json.NewDecoder(r.Body).Decode(&candidate); err != nil {
        http.Error(w, "Failed to parse ICE candidate", http.StatusBadRequest)
        return
    }

    mutex.Lock()
    defer mutex.Unlock()
    if pc, ok := peerConnections[candidate.ChannelID]; ok {
        if err := pc.AddICECandidate(candidate.ICECandidateInit); err != nil {
            http.Error(w, "Failed to add ICE candidate", http.StatusInternalServerError)
            return
        }
    }

    w.WriteHeader(http.StatusOK)
}

func notifyUsers(channelID string, msg UserMessage) {
    mutex.Lock()
    defer mutex.Unlock()
    for id, pc := range peerConnections {
        if id == channelID {
            continue
        }
        go func(pc *webrtc.PeerConnection) {
            // Simuler l'envoi d'un message pour notifier les autres utilisateurs
            log.Printf("Notifying user about new user in channel: %s", msg.ChannelID)
        }(pc)
    }
}
