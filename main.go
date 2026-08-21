package main

import (
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/ssneandrel/happ-decoder-go/decoder"
)

func subHandler(w http.ResponseWriter, r *http.Request) {
	targetURL := r.URL.Query().Get("url")
	if targetURL == "" {
		http.Error(w, "Параметр 'url' обязателен. Пример: /sub?url=happ://crypt5/...", http.StatusBadRequest)
		return
	}

	result, err := decoder.DecryptHappURL(targetURL)
	if err != nil {
		http.Error(w, fmt.Sprintf("Ошибка расшифровки: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(result))
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("OK"))
}

func main() {
	port := flag.String("port", "8080", "Порт HTTP сервера")
	flag.Parse()

	if envPort := os.Getenv("PORT"); envPort != "" {
		*port = envPort
	}

	http.HandleFunc("/sub", subHandler)
	http.HandleFunc("/health", healthHandler)

	log.Printf("Запуск Happ Decoder сервера на порту :%s...", *port)
	if err := http.ListenAndServe(":"+*port, nil); err != nil {
		log.Fatalf("Ошибка запуска сервера: %v", err)
	}
}
