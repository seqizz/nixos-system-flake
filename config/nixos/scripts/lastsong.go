package main

import (
    "encoding/json"
    "io/ioutil"
    "log"
    "net/http"
    "os"
    "strings"
    "sync"
    "time"
)

type SongData struct {
    CurrentSong string    `json:"current_song"`
    SongLink    string    `json:"song_link"`
    UpdateTime  time.Time `json:"update_time"`
}

type incomingData map[string]string

var (
    songData SongData
    mutex    sync.RWMutex
    outputFile = "/shared/vhosts/gurkan.in/public/current-song.json"
)

func main() {
    http.HandleFunc("/update", func(w http.ResponseWriter, r *http.Request) {
        if r.Method != http.MethodPost {
            log.Printf("Wrong method: %s", r.Method)
            http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
            return
        }

        // Read raw body
        body, err := ioutil.ReadAll(r.Body)
        if err != nil {
            log.Printf("Error reading body: %v", err)
            http.Error(w, err.Error(), http.StatusBadRequest)
            return
        }
        log.Printf("Raw body: %s", string(body))

        // Clean up JSON
        cleanJSON := strings.NewReplacer(": ", ":", ", ", ",").Replace(string(body))
        log.Printf("Cleaned JSON: %s", cleanJSON)

        // First decode into a map
        var incoming incomingData
        if err := json.Unmarshal([]byte(cleanJSON), &incoming); err != nil {
            log.Printf("Error unmarshaling JSON: %v", err)
            http.Error(w, err.Error(), http.StatusBadRequest)
            return
        }
        log.Printf("Decoded incoming data: %+v", incoming)

        mutex.Lock()
        songData = SongData{
            CurrentSong: incoming["current_song"],
            SongLink:    incoming["song_link"],
            UpdateTime:  time.Now(),
        }

        jsonData, err := json.Marshal(songData)
        if err != nil {
            log.Printf("Error marshaling JSON: %v", err)
            http.Error(w, "Internal server error", http.StatusInternalServerError)
            mutex.Unlock()
            return
        }

        log.Printf("Writing data: %s", string(jsonData))

        err = os.WriteFile(outputFile, jsonData, 0644)
        if err != nil {
            log.Printf("Error writing file: %v", err)
            http.Error(w, "Internal server error", http.StatusInternalServerError)
            mutex.Unlock()
            return
        }
        mutex.Unlock()

        w.WriteHeader(http.StatusOK)
    })

    log.Printf("Starting server on localhost:7700")
    log.Fatal(http.ListenAndServe("localhost:7700", nil))
}

