import java.io.*;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import processing.data.Table;
import processing.data.TableRow;
import peasy.PeasyCam;
import java.util.ArrayList;

// Global variables setup
Table table;
ArrayList<PVector> wordPositions;
ArrayList<String> words;
float scaleFactor = 5;
PeasyCam cam;
float threshold = 20000; // Adjusted threshold to reduce line density
float textSize = 40;
int lineColor = color(255, 204, 0); // Default line color, fetched color will be stored here
String accessToken; // Access token will be set in the authenticate function
String clientId = "Pd57TRiErU6uHq7iqHM2JttPGqZdBBwl"; // Actual client ID
String clientSecret = "wk2BcrPN4rttE2vfhwF0aeSkJKiQvQAgVH7OsnTw1FWCVFPNcJgNk0jj4lmLowO7"; // Actual client secret
String thingId = "41b3d3ba-7225-4a0c-8995-3f669ca951ea"; // Thing ID
String propertyUUID = "3181daae-5e16-4555-9ef8-d0e9bbf3f6dd"; // Property UUID
PVector defaultCameraPosition = new PVector(0, 0, 1000);

void setup() {
  fullScreen(P3D, 1);
  smooth(2);
  colorMode(HSB, 360, 100, 100);
  cam = new PeasyCam(this, 1000);
  cam.setMinimumDistance(300);
  cam.setMaximumDistance(5000);

  table = loadTable("scaled_word_list_with_coordinates.csv", "header");
  wordPositions = new ArrayList<PVector>();
  words = new ArrayList<String>();

  PVector center = new PVector(0, 0, 0);

  for (TableRow row : table.rows()) {
    String word = row.getString("word").toLowerCase();
    float x = row.getFloat("x") * scaleFactor;
    float y = row.getFloat("y") * scaleFactor;
    float z = row.getFloat("z") * scaleFactor;
    PVector pos = new PVector(x, y, z);
    wordPositions.add(pos);
    words.add(word);
    center.add(pos);
  }

  center.div(wordPositions.size());
  cam.lookAt(center.x, center.y, center.z);

  authenticate(); // Authenticate on setup
}

void draw() {
  background(0);

  // Update the color more frequently
  if (frameCount % 60 == 0) {
    fetchWordcloudColor();
  }

  for (int i = 0; i < wordPositions.size(); i++) {
    PVector pos = wordPositions.get(i);
    String word = words.get(i);
    for (int j = i + 1; j < wordPositions.size(); j++) {
      PVector otherPos = wordPositions.get(j);
      float distance = PVector.dist(pos, otherPos);
      if (distance < threshold) {
        stroke(lineColor, 100);
        line(pos.x, pos.y, pos.z, otherPos.x, otherPos.y, otherPos.z);
      }
    }

    pushMatrix();
    translate(pos.x, pos.y, pos.z);
    fill(255);
    textSize(textSize);
    text(word, 0, 0);
    popMatrix();
  }
}

void mousePressed() {
  if (mouseButton == RIGHT) {
    PVector center = new PVector(0, 0, 0);
    for (PVector pos : wordPositions) {
      center.add(pos);
    }
    center.div(wordPositions.size());
    cam.lookAt(center.x, center.y, center.z);
  }
}

void authenticate() {
  try {
    URL url = new URL("https://api2.arduino.cc/iot/v1/clients/token");
    HttpURLConnection con = (HttpURLConnection) url.openConnection();
    con.setRequestMethod("POST");
    con.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
    con.setDoOutput(true);

    String data = "grant_type=client_credentials&client_id=" + clientId + "&client_secret=" + clientSecret + "&audience=https://api2.arduino.cc/iot";
    OutputStream os = con.getOutputStream();
    byte[] input = data.getBytes(StandardCharsets.UTF_8);
    os.write(input, 0, input.length);
    os.close();

    BufferedReader br = new BufferedReader(new InputStreamReader(con.getInputStream(), StandardCharsets.UTF_8));
    StringBuilder response = new StringBuilder();
    String responseLine;
    while ((responseLine = br.readLine()) != null) {
      response.append(responseLine.trim());
    }
    br.close();

    JSONObject json = parseJSONObject(response.toString());
    accessToken = json.getString("access_token");
    println("Token fetched successfully: " + accessToken);
  } catch (Exception e) {
    println("Authentication failed: " + e.getMessage());
  }
}

void refreshToken() {
  authenticate(); // Reuse the authenticate function to renew the token
}

void fetchWordcloudColor() {
  try {
    URL url = new URL("https://api2.arduino.cc/iot/v2/things/" + thingId + "/properties/" + propertyUUID);
    HttpURLConnection connection = (HttpURLConnection) url.openConnection();
    connection.setRequestMethod("GET");
    connection.setRequestProperty("Authorization", "Bearer " + accessToken);
    connection.connect();

    BufferedReader reader = new BufferedReader(new InputStreamReader(connection.getInputStream()));
    StringBuilder result = new StringBuilder();
    String line;
    while ((line = reader.readLine()) != null) {
      result.append(line);
    }
    reader.close();

    JSONObject json = parseJSONObject(result.toString());
    if (json != null && json.getJSONObject("last_value") != null) {
      JSONObject lastValue = json.getJSONObject("last_value");
      float hue = lastValue.getFloat("hue");
      float sat = lastValue.getFloat("sat");
      float bri = lastValue.getFloat("bri");
      lineColor = color(hue, sat, bri); // Update the line color based on fetched data
      println("Color updated from Arduino Cloud: Hue " + hue + ", Saturation " + sat + ", Brightness " + bri);
    } else {
      println("Invalid or missing JSON data");
    }
  } catch (Exception e) {
    println("Failed to fetch color: " + e.getMessage());
  }
}
