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
	var offer webrtc.SessionDescription
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
	peerConnections[offer.SDP] = peerConnection
	mutex.Unlock()

	peerConnection.OnICECandidate(func(candidate *webrtc.ICECandidate) {
		if candidate == nil {
			return
		}

		// Broadcast ICE candidate to other connected peers
		for _, pc := range peerConnections {
			if pc != peerConnection {
				_ = pc.AddICECandidate(candidate.ToJSON())
			}
		}
	})

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

	// Add ICE candidate to all peer connections
	mutex.Lock()
	defer mutex.Unlock()
	for _, pc := range peerConnections {
		if err := pc.AddICECandidate(candidate); err != nil {
			http.Error(w, "Failed to add ICE candidate", http.StatusInternalServerError)
			return
		}
	}

	w.WriteHeader(http.StatusOK)
}
