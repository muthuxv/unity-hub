package services

import (
    "encoding/json"
    "net/http"

    "github.com/pion/webrtc/v3"
)

var peerConnection *webrtc.PeerConnection

func init() {
    var err error
    peerConnection, err = webrtc.NewPeerConnection(webrtc.Configuration{})
    if err != nil {
        panic(err)
    }
}

func SDPHandler(w http.ResponseWriter, r *http.Request) {
    var offer webrtc.SessionDescription
    if err := json.NewDecoder(r.Body).Decode(&offer); err != nil {
        http.Error(w, "Failed to parse offer", http.StatusBadRequest)
        return
    }

    if err := peerConnection.SetRemoteDescription(offer); err != nil {
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
    var candidate webrtc.ICECandidateInit
    if err := json.NewDecoder(r.Body).Decode(&candidate); err != nil {
        http.Error(w, "Failed to parse ICE candidate", http.StatusBadRequest)
        return
    }

    if err := peerConnection.AddICECandidate(candidate); err != nil {
        http.Error(w, "Failed to add ICE candidate", http.StatusInternalServerError)
        return
    }

    w.WriteHeader(http.StatusOK)
}
