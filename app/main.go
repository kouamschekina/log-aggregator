package main

import (
	"log/slog"
	"math/rand"
	"os"
	"time"
)

func main() {
	// Configure JSON logger to stdout
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	slog.SetDefault(logger)

	// Seed the random generator so log output varies across runs.
	rand.Seed(time.Now().UnixNano())

	levels := []slog.Level{slog.LevelInfo, slog.LevelError, slog.LevelDebug}
	messages := []string{
		"User logged in",
		"Failed to connect to database",
		"Processing request",
		"Data validation failed",
		"Connection timeout",
		"Cache hit",
		"Cache miss",
		"Starting background job",
	}

	logger.Info("Starting log generator service", "version", "1.0.0")

	for {
		level := levels[rand.Intn(len(levels))]
		msg := messages[rand.Intn(len(messages))]
		
		// Add some extra contextual data randomly
		userID := rand.Intn(1000)
		latency := time.Duration(rand.Intn(500)) * time.Millisecond

		switch level {
		case slog.LevelInfo:
			logger.Info(msg, "user_id", userID, "latency", latency.String())
		case slog.LevelError:
			logger.Error(msg, "user_id", userID, "error_code", rand.Intn(500)+500)
		case slog.LevelDebug:
			logger.Debug(msg, "user_id", userID, "details", "some internal details")
		}

		// Sleep between 0.5s and 2s
		sleepDuration := time.Duration(rand.Intn(1500) + 500) * time.Millisecond
		time.Sleep(sleepDuration)
	}
}
