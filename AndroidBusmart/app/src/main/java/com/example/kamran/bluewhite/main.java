package com.example.kamran.bluewhite;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.Context;
import android.os.Bundle;
import android.os.Vibrator;
import android.support.v7.app.AppCompatActivity;
import android.view.View;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.TextView;


import android.util.Log;

import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import org.json.JSONObject;

import com.google.gson.JsonObject;
import com.pubnub.api.PNConfiguration;
import com.pubnub.api.PubNub;
import com.pubnub.api.callbacks.SubscribeCallback;
import com.pubnub.api.callbacks.PNCallback;
import com.pubnub.api.enums.PNStatusCategory;
import com.pubnub.api.models.consumer.PNPublishResult;
import com.pubnub.api.models.consumer.PNStatus;
import com.pubnub.api.models.consumer.pubsub.PNMessageResult;
import com.pubnub.api.models.consumer.pubsub.PNPresenceEventResult;


import java.util.Arrays;



import com.google.android.gms.maps.*;
import com.google.android.gms.maps.model.*;


import static com.example.kamran.bluewhite.R.id.sin;

public class main extends AppCompatActivity {

    ImageView sback;
    TextView start;
    PubNub pubnub;
    Vibrator v;
    EditText start_stop;
    EditText end_stop;
    String start_name = "";
    String end_name = "";
    Boolean clicked = false;
    Boolean arrive = false;
    //String start_name = start_stop.getText().toString();
    //String end_name = end_stop.getText().toString();

    private boolean isEmpty(EditText etText) {
        return etText.getText().toString().trim().length() == 0;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_signin);

        start_stop = (EditText)findViewById(R.id.start_stop);
        end_stop = (EditText)findViewById(R.id.end_stop);

        v = (Vibrator) this.getSystemService(Context.VIBRATOR_SERVICE);

        PNConfiguration pnConfiguration = new PNConfiguration();
        pnConfiguration.setSubscribeKey("sub-c-ac319e2e-ee4c-11e6-b325-02ee2ddab7fe");
        pnConfiguration.setPublishKey("pub-c-275d4bd0-6556-4125-905c-a9f365a86a37");
        pnConfiguration.setSecure(false);

        pubnub = new PubNub(pnConfiguration);

        pubnub.addListener(new SubscribeCallback() {
            @Override
            public void status(PubNub pubnub, PNStatus status) {
                if (status.getCategory() == PNStatusCategory.PNConnectedCategory){
                    new AlertDialog.Builder(main.this)
                            .setTitle("Message")
                            .setMessage("PubNub Connected!")
                            .setIcon(android.R.drawable.ic_dialog_alert)
                            .show();
                }
            }

            // Listner for messages from PubNub
            /*/{
                   "channel":"Bus_Stop_C",
                           "action":0,
                           "last_update":"1486….",
                           "signal_id":"aef31ab..."
               }
            // action:  notifyServer use 0
            //              client use -1 and -2*/
            // get on: send {"action": -1}   off {"action": -2}
            @Override
            public void message(PubNub pubnub, final PNMessageResult message) {

                if(message.getChannel() != null) {


                    start_name = isEmpty(start_stop) ? "" : start_stop.getText().toString();
                    end_name = isEmpty(end_stop) ? "" : end_stop.getText().toString();


                    String listener_message = message.getMessage().getAsString();

                    Log.i("msg", listener_message);

                    try{
                        JSONObject message_json = new JSONObject(listener_message);
                        String listener_action = message_json.getString("action");
                        String listenter_channel = message_json.getString("channel");

                        if (listener_action == "0") {

                            //Log.i("EDITTEXT", start_name);
                            //Log.i("EDITTEXT", end_name);
                             if(!arrive){
                                 Log.i("BUS", "In !arrive if statement");
                                 Log.i("LISTN", listenter_channel+ " " + start_name);
                                 if(listenter_channel.equals(start_name)){
                                     v.vibrate(600);
                                     new Thread() {
                                         public void run() {
                                             main.this.runOnUiThread(new Runnable() {
                                                 public void run() {
                                                     new AlertDialog.Builder(main.this)
                                                             .setTitle("Message")
                                                             .setMessage("Your Bus is Here!")
                                                             .setIcon(android.R.drawable.ic_dialog_alert)
                                                             .show();
                                                 }
                                             });
                                         }
                                     }.start();

                                     JsonObject data = new JsonObject();
                                     data.addProperty("action", -1);
                                     Log.i("BUS", "上車");
                                     pubnub.publish().channel(start_name).message(data.toString()).async(new PNCallback<PNPublishResult>() {
                                         @Override
                                         public void onResponse(PNPublishResult result, PNStatus status) {
                                             // handle publish response
                                         }
                                     });

                                     arrive = true;
                                 }

                             }
                            else if(listenter_channel.equals(end_name)){

                                 v.vibrate(600);
                                 new Thread() {
                                     public void run() {
                                         main.this.runOnUiThread(new Runnable() {
                                             public void run() {
                                                 new AlertDialog.Builder(main.this)
                                                         .setTitle("Message")
                                                         .setMessage("You have arrived your destination!")
                                                         .setIcon(android.R.drawable.ic_dialog_alert)
                                                         .show();
                                             }
                                         });
                                     }
                                 }.start();


                                 JsonObject data2 = new JsonObject();

                                 data2.addProperty("action", -2);
                                 Log.i("BUS", "下車");
                                 pubnub.publish().channel(end_name).message(data2.toString()).async(new PNCallback<PNPublishResult>() {
                                     @Override
                                     public void onResponse(PNPublishResult result, PNStatus status) {
                                         // handle publish response
                                     }
                                 });

                                 arrive = false;
                                 clicked = false;
                                 pubnub.unsubscribeAll();
                             }
                        }

                    } catch(Throwable e){
                        Log.e("JSONObjectException", "JSONObjectException");
                    }
                }
            }

            @Override
            public void presence(PubNub pubnub, PNPresenceEventResult presence) {

            }
        });

        //pubnub.subscribe().channels(Arrays.asList("Bus_Stop_A")).execute();
        start = (TextView)findViewById(sin);
        start.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
            if(!clicked){
                start_name = start_stop.getText().toString();
                end_name = end_stop.getText().toString();
                JsonObject data = new JsonObject();
                data.addProperty("channel", start_name);
                data.addProperty("action", 1);
                Log.i("BUS", "Arrive Stop");
                pubnub.subscribe().channels(Arrays.asList(start_name, end_name)).execute();
                pubnub.publish().channel(start_name).message(data.toString()).async(new PNCallback<PNPublishResult>() {
                    @Override
                    public void onResponse(PNPublishResult result, PNStatus status) {
                        // handle publish response
                    }
                });
                clicked = true;
            }
            }
        });
    }


   /* public class MapPane extends Activity implements OnMapReadyCallback {

        @Override
        protected void onCreate(Bundle savedInstanceState) {
            super.onCreate(savedInstanceState);
            setContentView(R.layout.map_activity);

            MapFragment mapFragment = (MapFragment) getFragmentManager()
                    .findFragmentById(R.id.map);
            mapFragment.getMapAsync(this);
        }

        @Override
        public void onMapReady(GoogleMap map) {
            // Some buildings have indoor maps. Center the camera over
            // the building, and a floor picker will automatically appear.
            map.moveCamera(CameraUpdateFactory.newLatLngZoom(
                    new LatLng(-33.86997, 151.2089), 18));
        }
    }*/
}
