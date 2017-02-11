var express = require('express');
var app = express();
var PubNub = require('pubnub');


app.get('/', function (req, res) {
   res.send('Hello World');
})


var pubnub = new PubNub({
    subscribeKey: "sub-c-ac319e2e-ee4c-11e6-b325-02ee2ddab7fe",
    publishKey: "pub-c-275d4bd0-6556-4125-905c-a9f365a86a37"
})

var Bus_Stop_A = 0;
var Bus_Stop_B = 0;
var Bus_Stop_C = 0;
var bus_10036 = {"lat":1111, "lng":1111};
var bus_12036 = {"lat":1111, "lng":1111};
var bus_26036 = {"lat":1111, "lng":1111};
var bus_66035 = {"lat":1111, "lng":1111};
var bus_77034 = {"lat":1111, "lng":1111};



pubnub.addListener({
    status: function(statusEvent) {
        if (statusEvent.category === "PNConnectedCategory") {
            console.log("Connected!!");
        }
    },
    message: function(message) {
    	if(message.channel != "mapUpdater"){
	        // handle message
	        // var obj = JSON.parse(message);
	        // console.log(message.channel);

	        var isRefresh = true;
	        switch (message.channel){
	        	case "Bus_Stop_A":
	        		if(JSON.parse(message.message).action > 0){
	        			Bus_Stop_A += JSON.parse(message.message).action;
	        		}else{
	        			Bus_Stop_A = 0;
	        		}
	        		if(message.action != 0){
	        			isRefresh = true;
	        		}
	        		break;
	        	case "Bus_Stop_B":
	        		console.log(JSON.parse(message.message).action);
	        		if(JSON.parse(message.message).action > 0){
	        			Bus_Stop_B += JSON.parse(message.message).action;
	        		}else{
	        			Bus_Stop_B = 0;
	        		}
	        		console.log(Bus_Stop_B);
	        		if(message.action != 0){
	        			isRefresh = true;
	        		}
	        		break;
        		case "Bus_Stop_C":
        			if(JSON.parse(message.message).action > 0){
        				Bus_Stop_C += JSON.parse(message.message).action;
        			}else{
        				Bus_Stop_C = 0;
        			}
        			if(message.action != 0){
	        			isRefresh = true;
	        		}
	        		break;
	        	case "All_Bus_Info":
	        		isRefresh = true;
	        		switch(message.bus_id){
	        			case "10036":
	        				bus_10036.lat = message.latitude;
	        				bus_10036.lng = message.latitude;
	        				break;
	        			case "12036":
	        				bus_12036.lat = message.latitude;
	        				bus_12036.lng = message.latitude;
	        				break;
	        			case "26036":
	        				bus_26036.lat = message.latitude;
	        				bus_26036.lng = message.latitude;
	        				break;
	        			case "66035":
	        				bus_66035.lat = message.latitude;
	        				bus_66035.lng = message.latitude;
	        				break;
	        			case "77034":
	        				bus_66035.lat = message.latitude;
	        				bus_66035.lng = message.latitude;
	        				break;

	        		}

	        		break;

	        }	

	        msg_json={
	            	"Bus_Stop_A": Bus_Stop_A,            
	            	"Bus_Stop_B": Bus_Stop_B, 
	            	"Bus_Stop_C": Bus_Stop_C, 
	            	"bus_10036": bus_10036, 
	            	"bus_12036": bus_12036, 
	            	"bus_26036": bus_26036, 
	            	"bus_66035": bus_66035, 
	            	"bus_77034": bus_77034
	            };

	        if(isRefresh){
		        pubnub.publish({
		            channel : "mapUpdater",
		            message : msg_json
		        });
			}
	        console.log(message.channel);
        }
    },
    presence: function(presenceEvent) {
        // handle presence
    }
})
  
pubnub.subscribe({ 
    channels: ["Bus_Stop_A","Bus_Stop_B","Bus_Stop_C","All_Bus_Info", "mapUpdater"]
});



var server = app.listen(8081, function () {
   var host = server.address().address;
   var port = server.address().port;
   
   console.log("Map Updater Start Running ..... ");
})