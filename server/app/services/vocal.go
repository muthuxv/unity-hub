package services

import (
    "encoding/json"
    "net/http"
    "sync"

    "github.com/pion/webrtc/v3"
)

var (
    peerConnections = make(map[string]*webrtc.PeerConnection)
    mutex           sync.Mutex
)

func SDPHandler(w http.ResponseWriter, r *http.Request) {
    var offer struct {
        webrtc.SessionDescription
        ChannelID string `json:"channel_id"`
    }
    if err := json.NewDecoder(r.Body).Decode(&offer); err != nil {
        http.Error(w, "Failed to parse offer", http.StatusBadRequest)
        return
    }

    peerConnection, err := webrtc.NewPeerConnection(webrtc.Configuration{})
    if err != nil {
        http.Error(w, "Failed to create peer connection", http.StatusInternalServerError)
        return
    }

    mutex.Lock()
    peerConnections[offer.ChannelID] = peerConnection
    mutex.Unlock()

    peerConnection.OnICECandidate(func(candidate *webrtc.ICECandidate) {
        if candidate == nil {
            return
        }

        mutex.Lock()
        defer mutex.Unlock()
        for id, pc := range peerConnections {
            if id != offer.ChannelID {
                _ = pc.AddICECandidate(candidate.ToJSON())
            }
        }
    })

    peerConnection.OnTrack(func(track *webrtc.TrackRemote, receiver *webrtc.RTPReceiver) {
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

    answer, err := peerConnection.CreateAnswer(nil)
    if err != nil {
        http.Error(w, "Failed to create answer", http.StatusInternalServerError)
        return
    }

    if err := peerConnection.SetLocalDescription(answer); err != nil {
        http.Error(w, "Failed to set local description", http.StatusInternalServerError)
        return
    }

    json.NewEncoder(w).Encode(answer)
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
