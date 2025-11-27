package helpers

import (
	"context"
	"mime/multipart"
	"time"

	domainApp "github.com/aldinokemal/go-whatsapp-web-multidevice/domains/app"
	"github.com/sirupsen/logrus"
	"go.mau.fi/whatsmeow"
)

func SetAutoConnectAfterBooting(service domainApp.IAppUsecase) {
	time.Sleep(2 * time.Second)
	_ = service.Reconnect(context.Background())
}

func SetAutoReconnectChecking(cli *whatsmeow.Client) {
	// Run every 5 minutes to check if the connection is still alive, if not, reconnect
	go func() {
		for {
			time.Sleep(5 * time.Minute)
			if cli != nil {
				// Check both connection and login status
				if !cli.IsConnected() {
					// If disconnected, try to reconnect
					logrus.Info("[AUTO_RECONNECT] Connection lost, attempting to reconnect...")
					if err := cli.Connect(); err != nil {
						logrus.Errorf("[AUTO_RECONNECT] Reconnect failed: %v", err)
						time.Sleep(30 * time.Second) // Wait a bit before next check if reconnect failed
					} else {
						// Wait a moment to check if login was restored
						time.Sleep(3 * time.Second)
						if cli.IsLoggedIn() {
							logrus.Info("[AUTO_RECONNECT] ✅ Successfully reconnected and logged in - session restored!")
						} else if cli.Store.ID != nil {
							// We have a device ID but not logged in - this might be a preserved session
							logrus.Info("[AUTO_RECONNECT] Connected but not logged in - session may be preserved, waiting...")
						}
					}
				} else if cli.IsConnected() && !cli.IsLoggedIn() {
					// Connected but not logged in - try to restore session
					if cli.Store.ID != nil {
						logrus.Info("[AUTO_RECONNECT] Connected but not logged in - attempting to restore session...")
						// The session might be preserved, just wait a bit for WhatsApp to restore it
						// WhatsApp will automatically restore the session if the other device disconnects
						time.Sleep(10 * time.Second)
						if !cli.IsLoggedIn() {
							// Still not logged in, try reconnecting
							cli.Disconnect()
							time.Sleep(2 * time.Second)
							if err := cli.Connect(); err != nil {
								logrus.Errorf("[AUTO_RECONNECT] Failed to restore session: %v", err)
							}
						}
					}
				}
			}
		}
	}()
}

func MultipartFormFileHeaderToBytes(fileHeader *multipart.FileHeader) []byte {
	file, _ := fileHeader.Open()
	defer file.Close()

	fileBytes := make([]byte, fileHeader.Size)
	_, _ = file.Read(fileBytes)

	return fileBytes
}
