package main

import (
	crypto_rand "crypto/rand"
	"encoding/json"
	"fmt"
	"github.com/pubnub/go/messaging"
	"io"
	"net/http"
	"strconv"
	"time"
)

// Global variables
var my_pubkey = "pub-c-275d4bd0-6556-4125-905c-a9f365a86a37"
var my_subkey = "sub-c-ac319e2e-ee4c-11e6-b325-02ee2ddab7fe"
var my_channel = "All_Bus_Info"
var db_addr = "54.191.90.246:27017"
var BusStopMap = make(map[Coordinate]string)

var pubnub = messaging.NewPubnub(my_pubkey, my_subkey, "", "", false, "")

type SensorSignal struct {
	ChannelID string  `json:"channel"`
	SignalID  string  `json:"signal_id"`
	SensorID  string  `json:"sensor_id"`
	BusID     string  `json:"bus_id"`
	TimeStamp string  `json:"last_update"`
	Value     float64 `json:"value"`
	Unit      string  `json:"unit"`
	Long      float64 `json:"longitude"`
	Lat       float64 `json:"latitude"`
}

type NotifyArriveSignal struct {
	ChannelID string `json:"channel"`
	Action    int    `json:"action"`
	TimeStamp string `json:"last_update"`
	SignalID  string `json:"signal_id"`
}

type Coordinate struct {
	Long float64
	Lat  float64
}

// newUUID generates a random UUID according to RFC 4122
func newUUID() (string, error) {
	uuid := make([]byte, 16)
	n, err := io.ReadFull(crypto_rand.Reader, uuid)
	if n != len(uuid) || err != nil {
		return "", err
	}
	// variant bits; see section 4.1.1
	uuid[8] = uuid[8]&^0xc0 | 0x80
	// version 4 (pseudo-random); see section 4.1.3
	uuid[6] = uuid[6]&^0xf0 | 0x40
	return fmt.Sprintf("%x-%x-%x-%x-%x", uuid[0:4], uuid[4:6], uuid[6:8], uuid[8:10], uuid[10:]), nil
}

func subscribeSensorInfo() {
	pubnub := messaging.NewPubnub(my_pubkey, my_subkey, "", "", false, "")
	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)

	go pubnub.Subscribe(my_channel, "", successChannel, false, errorChannel)

	go func() {
		for {
			select {
			case response := <-successChannel:
				var msg []interface{}

				err := json.Unmarshal(response, &msg)
				if err != nil {
					fmt.Println(err)
					return
				}
				//fmt.Println("got msg!") //Test
				switch m := msg[0].(type) {
				case float64:
					fmt.Println(msg[1].(string))
				case []interface{}:
					//fmt.Printf("Received message '%s' on channel '%s'\n", m[0], msg[2]) //m[0]:the JSON data. msg[2]=channel ID
					var signal SensorSignal
					err := json.Unmarshal([]byte(m[0].(string)), &signal)
					if err == nil {
						//fmt.Println("long:", signal.Long)
						//fmt.Println("lat:", signal.Lat)
						chID := isHitBusStop(signal.Long, signal.Lat)
						if chID != "" {
							fmt.Println("long:", signal.Long)
							fmt.Println("lat:", signal.Lat)
							notifyChannel(chID)
						}
					} else {
						fmt.Println("Unmarshal failed! =>", err)
					}
				default:
					panic(fmt.Sprintf("Unknown type: %T", m))
				}

			case err := <-errorChannel:
				fmt.Println(string(err))
			case <-messaging.SubscribeTimeout():
				fmt.Println("Subscribe() timeout")
			}
		}
	}()
}

func notifyChannel(chanID string) {
	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	fmt.Println("Ready to notify channel: ", chanID)

	var signal NotifyArriveSignal
	signal.ChannelID = chanID
	signal.Action = 0
	signal.TimeStamp = strconv.FormatInt(time.Now().UnixNano(), 10)
	signal.SignalID, _ = newUUID()

	j, _ := json.Marshal(signal)
	go pubnub.Publish(chanID, string(j), successChannel, errorChannel)

	select {
	case response := <-successChannel:
		fmt.Println(string(response))
		fmt.Println("Sent Message " + string(j))
	case err := <-errorChannel:
		fmt.Println(string(err))
	case <-messaging.Timeout():
		fmt.Println("Publish() timeout")
	}
}

func isHitBusStop(Long float64, Lat float64) string {

	_, ok := BusStopMap[Coordinate{Long, Lat}] // if this coordinate founds in the hashmap
	if ok {
		fmt.Println("Arrived!", BusStopMap[Coordinate{Long, Lat}])
		return BusStopMap[Coordinate{Long, Lat}]
	}
	return ""

}

func initBusStopChannel() {
	BusStopMap[Coordinate{Long: -122.14292, Lat: 37.44198}] = "Bus_Stop_A"
	BusStopMap[Coordinate{Long: -122.10125, Lat: 37.42798}] = "Bus_Stop_B"
	BusStopMap[Coordinate{Long: -121.89964, Lat: 37.43222}] = "Bus_Stop_C"

	/* // For Test purpose only. It can be remove.
	for k, v := range BusStopMap {
	fmt.Println("Key:", k.Long, ",", k.Lat, "Value:", v)
	}

	x := -122.14292
	y := 37.44198

	_, ok := BusStopMap[Coordinate{x, y}] // if this coordinate founds in the hashmap
	if ok {
		fmt.Println("Arrived!", BusStopMap[Coordinate{x, y}])

		successChannel := make(chan []byte)
		errorChannel := make(chan []byte)

		j := "Ding Don!"
		go func() {
			for {
				time.Sleep(10000 * time.Millisecond)
				go pubnub.Publish(BusStopMap[Coordinate{x, y}], string(j), successChannel, errorChannel)

				select {
				case response := <-successChannel:
					fmt.Println(string(response))
					fmt.Println("Sent Message " + string(j))
				case err := <-errorChannel:
					fmt.Println(string(err))
				case <-messaging.Timeout():
					fmt.Println("Publish() timeout")
				}
			}
		}()
	}*/

	/*
		// For test purpose, directly notify and send message
		successChannel := make(chan []byte)
		errorChannel := make(chan []byte)

		j := "Ding Don!"
		go func() {
			for {
				time.Sleep(10000 * time.Millisecond)
				go pubnub.Publish("Bus_Stop_B", string(j), successChannel, errorChannel)

				select {
				case response := <-successChannel:
					fmt.Println(string(response))
					fmt.Println("Sent Message " + string(j))
				case err := <-errorChannel:
					fmt.Println(string(err))
				case <-messaging.Timeout():
					fmt.Println("Publish() timeout")
				}
			}
		}()
	*/
}

func main() {
	fmt.Println("PubNub SDK for go;", messaging.VersionInfo())
	initBusStopChannel()
	subscribeSensorInfo()
	http.ListenAndServe(":8080", nil)
}
