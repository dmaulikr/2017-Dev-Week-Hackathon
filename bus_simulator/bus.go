package main

import (
	crypto_rand "crypto/rand"
	"encoding/json"
	"fmt"
	"github.com/gorilla/mux"
	"github.com/kr/pretty"
	"github.com/pubnub/go/messaging"
	"golang.org/x/net/context"
	"googlemaps.github.io/maps"
	"gopkg.in/mgo.v2"
	"html/template"
	"io"
	"log"
	"math/rand"
	"net/http"
	"strconv"
	"strings"
	"time"
)

// The main sensor provider page.
func home(w http.ResponseWriter, r *http.Request) {

	var templates = template.Must(template.New("locateip").ParseFiles("sensorAdd.html"))

	err := templates.ExecuteTemplate(w, "sensorAdd.html", nil)

	if err != nil {
		panic(err)
	}

}

type SensorProfile struct {
	ID            string `json:"SensorID"`
	Name          string `json:"SensorName"`
	Type          int
	State         int
	Value         float64
	Unit          string
	HostVehicleID string
	Group         int
	Long          float64
	Lat           float64
	xy_group      int
	xy_index      int
	xy_direction  int
}

type SensorSignal struct {
	SignalID  string  `json:"signal_id"`
	SensorID  string  `json:"sensor_id"`
	BusID     string  `json:"bus_id"`
	TimeStamp string  `json:"last_update"`
	Value     float64 `json:"value"`
	Unit      string  `json:"unit"`
	Long      float64 `json:"longitude"`
	Lat       float64 `json:"latitude"`
}

type AddSensorReq struct {
	SensorName    string
	SensorType    int
	HostVehicleID string
}

type AddSensorRes struct {
	SensorID      string
	SensorName    string
	SensorType    int
	SensorState   int
	HostVehicleID string
}

type Coordinate struct {
	longitude float64
	latitude  float64
	altitude  float64
}

// Global variables
var sensorMap = make(map[string]SensorProfile)
var trafficOn int = 0
var my_pubkey = "pub-c-275d4bd0-6556-4125-905c-a9f365a86a37"
var my_subkey = "sub-c-ac319e2e-ee4c-11e6-b325-02ee2ddab7fe"
var my_channel = "All_Bus_Info"
var db_addr = "54.191.90.246:27017"
var xyMap = make(map[int][]Coordinate)
var busSpeed = 100

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

func float_rand(start_num float64, end_num float64) float64 {
	rand.Seed(time.Now().UnixNano())
	return rand.Float64()*(end_num-start_num) + start_num
}

func noiseGen() float64 {
	return float_rand(40, 130) // the unit is dB: decibel
}

func airPollutionGen() float64 {
	return float_rand(1, 10) // the unit is AQI: Air Quaility Index
}

func signalHelper(sensor *SensorProfile, signal *SensorSignal) {
	signal.SignalID, _ = newUUID()
	signal.SensorID = sensor.ID
	signal.BusID = sensor.HostVehicleID
	signal.TimeStamp = strconv.FormatInt(time.Now().UnixNano(), 10)

	// sensor type is noise
	if sensor.Type == 1 {
		signal.Value = noiseGen()
		signal.Unit = "dB"
	} else if sensor.Type == 2 {
		signal.Value = airPollutionGen()
		signal.Unit = "AQI"
	}

	if sensor.xy_index == len(xyMap[sensor.xy_group])-1 {
		sensor.xy_direction = -1
	} else if sensor.xy_index == 0 {
		sensor.xy_direction = 1
	}
	sensor.xy_index += sensor.xy_direction

	sensor.Long = xyMap[sensor.xy_group][sensor.xy_index].longitude
	sensor.Lat = xyMap[sensor.xy_group][sensor.xy_index].latitude
	sensorMap[sensor.ID] = *sensor
	signal.Long = sensor.Long
	signal.Lat = sensor.Lat
}

func publishSensorInfo() {
	pubnub := messaging.NewPubnub(my_pubkey, my_subkey, "", "", false, "")
	fmt.Println("PubNub SDK for go;", messaging.VersionInfo())
	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)

	for {
		if trafficOn > 0 {
			for _, sensor := range sensorMap {
				time.Sleep(time.Duration(busSpeed) * time.Millisecond)
				//j, _ := json.Marshal(value)
				//fmt.Println(string(j))
				if sensor.State == 1 {
					var signal SensorSignal
					signalHelper(&sensor, &signal)

					j, _ := json.Marshal(signal)
					go pubnub.Publish(my_channel, string(j), successChannel, errorChannel)

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
			}
		}
	}
}

func subscribeSensorInfo() {
	pubnub := messaging.NewPubnub(my_pubkey, my_subkey, "", "", false, "")
	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)

	//go pubnub.Subscribe(my_channel, "", successChannel, false, errorChannel)
	go pubnub.Subscribe("Bus_Stop_A", "", successChannel, false, errorChannel)

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
				fmt.Println("got msg!") //Test
				switch m := msg[0].(type) {
				case float64:
					fmt.Println(msg[1].(string))
				case []interface{}:
					fmt.Printf("Received message '%s' on channel '%s'\n", m[0], msg[2])
					//return
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

func trafficAllONHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Println("All Traffic ON = " + strconv.Itoa(trafficOn))
	trafficOn = 1
	fmt.Println("All Traffic ON = " + strconv.Itoa(trafficOn))
}

func trafficSensorONHandler(w http.ResponseWriter, r *http.Request) {
	sensorID := r.URL.Query()["sensorid"][0]
	if sensorID == "" {
		var str string = "Please give a sensor ID"
		http.Error(w, str, 400)
		return
	}

	fmt.Println("Query Sensor ID = ", sensorID)
	sensor, ok := sensorMap[sensorID]
	if !ok {
		var str string = "Not found Sensor ID: " + sensorID
		http.Error(w, str, 400)
		return
	} else {
		sensor.State = 1
		sensorMap[sensorID] = sensor
		fmt.Printf("Sensor state is %d on now ID %s \n", sensorMap[sensorID].State, sensorID)
		json.NewEncoder(w).Encode(sensor)
	}
}

func trafficAllOFFHandler(w http.ResponseWriter, r *http.Request) {

	fmt.Println("All Traffic OFF = " + strconv.Itoa(trafficOn))
	trafficOn = 0
	fmt.Println("All Traffic OFF = " + strconv.Itoa(trafficOn))
}

func trafficSensorOFFHandler(w http.ResponseWriter, r *http.Request) {
	sensorID := r.URL.Query()["sensorid"][0]
	if sensorID == "" {
		var str string = "Please give a sensor ID"
		http.Error(w, str, 400)
		return
	}

	fmt.Println("Query Sensor ID = ", sensorID)
	sensor, ok := sensorMap[sensorID]
	if !ok {
		var str string = "Not found Sensor ID: " + sensorID
		http.Error(w, str, 400)
		return
	} else {
		sensor.State = 0
		sensorMap[sensorID] = sensor
		fmt.Printf("Sensor state is %d on now ID %s \n", sensorMap[sensorID].State, sensorID)
		json.NewEncoder(w).Encode(sensor)
	}
}

func deleteSensorHandler(w http.ResponseWriter, r *http.Request) {
	sensorID := r.URL.Query()["sensorid"][0]
	if sensorID == "" {
		var str string = "Please give a sensor ID"
		http.Error(w, str, 400)
		return
	}

	fmt.Println("Query Sensor ID = ", sensorID)
	_, ok := sensorMap[sensorID]
	if !ok {
		var str string = "Not found Sensor ID: " + sensorID
		http.Error(w, str, 400)
		return
	} else {
		delete(sensorMap, sensorID)
		fmt.Printf("Delete Sensor ID %s \n", sensorID)
		json.NewEncoder(w).Encode(sensorMap)
	}
}

func showGmap(w http.ResponseWriter, r *http.Request) {
	fmt.Println("enter show google map")
	sensorID := r.URL.Query()["sensorid"][0]
	if sensorID == "" {
		var str string = "Please give a sensor ID"
		http.Error(w, str, 400)
		return
	}

	var templates = template.Must(template.New("locateip").ParseFiles("gmapExample.html"))
	p := SensorProfile{ID: sensorID}
	err := templates.ExecuteTemplate(w, "gmapExample.html", p)

	if err != nil {
		panic(err)
	}

}

func addSensor2DB(sensor SensorProfile) {
	session, err := mgo.Dial(db_addr)
	if err != nil {
		panic(err)
		fmt.Println("cannot connet to the mongo DB!!!!")
	}
	defer session.Close()
	session.SetMode(mgo.Monotonic, true)
	fmt.Println("ready to add sensor to DB!")

	/*var s SensorProfile
	j, _ := json.Marshal(sensor)
	err = json.Unmarshal([]byte(j), &s)
	if err != nil {
		fmt.Println("json decode fail!!!")
		return
	}*/

	c := session.DB("fullstack").C("sensor")
	err = c.Insert(sensor)
	if err != nil {
		fmt.Println(err)
		return
	}
	fmt.Printf("Added a new sensor %s to DB \n", sensor.ID)
}

func addSensorHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Println("Enter addSensorHandler!")

	if r.Method == "POST" {
		if r.Body == nil {
			http.Error(w, "Please send a request body", 400)
			return
		}

		var sReq AddSensorReq
		err := json.NewDecoder(r.Body).Decode(&sReq)
		if err != nil {
			http.Error(w, err.Error(), 400)
			return
		}
		var sNew SensorProfile
		sNew.ID, err = newUUID()
		sNew.Name = sReq.SensorName
		sNew.Type = sReq.SensorType // 1: noise sensor; 2: air sensor
		sNew.State = 1
		sNew.Value = 0
		if sReq.SensorType == 1 {
			sNew.Unit = "db"
		} else if sReq.SensorType == 2 {
			sNew.Unit = "AQI"
		}
		sNew.HostVehicleID = sReq.HostVehicleID
		sNew.Group = 0
		sNew.Long = 0
		sNew.Lat = 0
		sNew.xy_group = len(sensorMap) % len(busLinesGeoInfo)
		sNew.xy_index = 0
		sNew.xy_direction = 1

		//fmt.Println("Sesnot ID = " + sNew.ID)

		sensorMap[sNew.ID] = sNew // add sensor in the management map
		//addSensor2DB(sNew)

		var sRes AddSensorRes
		sRes.SensorID = sensorMap[sNew.ID].ID
		sRes.SensorName = sensorMap[sNew.ID].Name
		sRes.SensorType = sNew.Type
		sRes.SensorState = sNew.State
		sRes.HostVehicleID = sNew.HostVehicleID
		json.NewEncoder(w).Encode(sRes)
	}
}

func showSensorListHandler(w http.ResponseWriter, r *http.Request) {

	fmt.Println("Enter showSensorListHandler!")

	if r.Method == "GET" {
		if r.Body == nil {
			http.Error(w, "Please send a request body", 400)
			return
		}
		json.NewEncoder(w).Encode(sensorMap)
	}

}

func gmapHandler() {
	c, err := maps.NewClient(maps.WithAPIKey("AIzaSyDNJXVRtebwIzQQauD8yddaXB8y4wyFqfg"))
	if err != nil {
		log.Fatalf("fatal error: %s", err)
	}
	r := &maps.DirectionsRequest{
		//Origin: "37.32741,-121.81021",
		//Origin:      "2240 E Capitol Expy, San Jose, CA 95122, USA",
		//Destination: "1249 Great Mall Dr, Milpitas, CA 95035, USA",
		Origin:      "37.32242, -121.81496",
		Destination: "37.4133, -121.89826",
	}
	resp, wayPoint, err := c.Directions(context.Background(), r)
	if err != nil {
		log.Fatalf("fatal error: %s", err)
	}

	pretty.Println(resp)
	pretty.Println(wayPoint)
}

func parseCoordinates() {
	//pretty.Println("enter")
	for i, busLine := range busLinesGeoInfo {
		for _, str := range strings.Split(busLine, " ") {
			s := strings.Split(str, ",")
			var location Coordinate
			location.longitude, _ = strconv.ParseFloat(s[0], 64)
			location.latitude, _ = strconv.ParseFloat(s[1], 64)
			location.altitude, _ = strconv.ParseFloat(s[2], 64)
			xyMap[i] = append(xyMap[i], location)
		}
	}
	//pretty.Println(xyMap)
	//pretty.Println("exit")
}

func main() {

	mux := mux.NewRouter()

	// Block of my sensor API
	mux.HandleFunc("/sensor-provider/", home)                                      // sensorAdd.html
	mux.HandleFunc("/sensor-provider/api/add-sensor", addSensorHandler)            // POST method
	mux.HandleFunc("/sensor-provider/api/show-sensor-list", showSensorListHandler) // Get  method
	mux.HandleFunc("/sensor-provider/api/traffic/on/", trafficAllONHandler)        // Get  method
	mux.HandleFunc("/sensor-provider/api/traffic/on", trafficSensorONHandler)      // Get  method
	mux.HandleFunc("/sensor-provider/api/traffic/off/", trafficAllOFFHandler)      // Get  method
	mux.HandleFunc("/sensor-provider/api/traffic/off", trafficSensorOFFHandler)    // Get  method
	mux.HandleFunc("/sensor-provider/api/delete-sensor", deleteSensorHandler)      // Get method
	mux.HandleFunc("/sensor-provider/api/gmap", showGmap)                          // gmapExample.html

	// Enable to publish sensor info
	trafficOn = 0
	subscribeSensorInfo()
	go publishSensorInfo()
	//gmapHandler()
	parseCoordinates()

	// Start to port 3000 for REST service
	http.ListenAndServe(":3000", mux)
}
