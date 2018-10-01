import java.time.*;
import java.time.format.*;
import de.bezier.guido.*;

// SVG basemap
PShape basemap;
// The geographic extents of the SVG basemap
float[] basemapExtents = { 6.190, 53.427, 6.280, 53.490 };

// Bird observations
Observation[] observations;
// The three birds in the dataset (hard-coded to save effort)
int[] birdIDs = { 166, 167, 169 };

// UI elements
Button button1, button2, button3;

// Inset map dimensions
double[] insetExtents = { 6.2213, 53.475, 6.2263, 53.478 };
float insetLeft, insetTop, insetWidth, insetHeight;
// The magnification of the inset relative to the main map
float insetMagnification;
// The extents (left, top, width, height) of the inset basemap, in window coordinates
float[] insetBasemapExtents;

// Available modes
enum Mode {
  OBSERVATIONS, PATHS, TRAILS
};

// Current mode
Mode currentMode = Mode.OBSERVATIONS;

// Converts geographic coordinates to a window position in pixels.
// It is converting a double to a float, so the transformation may
// not be reversible.
float lonToWindowX(double lon) {
  return (float)((lon - basemapExtents[0]) * width / (basemapExtents[2] - basemapExtents[0]));
}
float latToWindowY(double lat) {
  return (float)((height - 1) -
    ((lat - basemapExtents[1]) * height / (basemapExtents[3] - basemapExtents[1])));
}

// Same deal, but for the inset map. Note the coordinates returned
// are with respect to the entire window, for ease of drawing.
float lonToInsetX(double lon) {
  return insetBasemapExtents[0] + insetMagnification * lonToWindowX(lon);
}
float latToInsetY(double lat) {
  return insetBasemapExtents[1] + insetMagnification * latToWindowY(lat);
}

void setup() {
  // Load the basemap
  basemap = loadShape("basemap.svg");

  // Load the point data
  observations = loadObservationData("All data.txt");

  // Set up the UI
  Interactive.make(this);

  button1 = new Button("Observations", width - 270, height - 36, 80, 26);
  Interactive.on(button1, "click", this, "buttonClicked");

  button2 = new Button("Paths", width - 180, height - 36, 80, 26);
  Interactive.on(button2, "click", this, "buttonClicked");

  button3 = new Button("Trails", width - 90, height - 36, 80, 26);
  Interactive.on(button3, "click", this, "buttonClicked");

  // Set up an inset to magnify the nesting area
  insetWidth = 300;
  insetHeight = 270;
  insetLeft = 20;
  insetTop = height - insetHeight - 20;
  insetMagnification = min(insetWidth / (lonToWindowX(insetExtents[2]) - lonToWindowX(insetExtents[0])), 
    insetHeight / (latToWindowY(insetExtents[1]) - latToWindowY(insetExtents[3])));
  
  insetBasemapExtents = new float[4];
  // basemap width
  insetBasemapExtents[2] = insetMagnification * width;
  // basemap height
  insetBasemapExtents[3] = insetMagnification * height;
  // basemap left
  insetBasemapExtents[0] = insetLeft +
    (lonToWindowX(basemapExtents[0]) - lonToWindowX(insetExtents[0])) * insetMagnification;
  // basemap top
  insetBasemapExtents[1] = insetTop +
    (latToWindowY(basemapExtents[3]) - latToWindowY(insetExtents[3])) * insetMagnification;
}

void settings() {
  size((int)(800 * (basemapExtents[2] - basemapExtents[0]) /
    (basemapExtents[3] - basemapExtents[1])), 800);
}

void draw() {
  // Draw the basemap to fill the entire window (for now)
  shape(basemap, 0, 0, width, height);

  // Draw a magnification of the nesting area
  drawInsetMap();

  switch (currentMode) {
  case OBSERVATIONS: 
    drawObservations(); 
    break;
  case PATHS: 
    drawPaths(); 
    break;
  case TRAILS:
    drawTrails();
    break;
  }
}

void drawInsetMap() {
  clip(insetLeft, insetTop, insetWidth, insetHeight);
  shape(basemap, insetBasemapExtents[0], insetBasemapExtents[1], 
    insetBasemapExtents[2], insetBasemapExtents[3]);

  // Draw inset outline
  noFill();
  stroke(0);
  strokeWeight(1);
  rect(insetLeft, insetTop, insetWidth - 1, insetHeight - 1);

  fill(0);
  textAlign(LEFT, BOTTOM);
  text("Nesting area", 30, height - 30);

  noClip();
}

// Draw primitive helpers that draw in both the inset and the main map
void mappoint(double lon, double lat) {
  point(lonToWindowX(lon), latToWindowY(lat));
  
  // draw point inside inset as well, if it is within the bounds
  float insetX = lonToInsetX(lon);
  float insetY = latToInsetY(lat);
  if (insetX > insetLeft && insetX < insetLeft + insetWidth &&
    insetY > insetTop && insetY < insetTop + insetHeight) {
    point(insetX, insetY);
  }
}

void maptext(String text, double lon, double lat) {
  text(text, lonToWindowX(lon), latToWindowY(lat));
  
  // draw text inside inset as well, if it is within the bounds
  float insetX = lonToInsetX(lon);
  float insetY = latToInsetY(lat);
  if (insetX > insetLeft && insetX < insetLeft + insetWidth &&
    insetY > insetTop && insetY < insetTop + insetHeight) {
    text(text, insetX, insetY);
  }
}

void mapline(double lon1, double lat1, double lon2, double lat2) {
  line(lonToWindowX(lon1), latToWindowY(lat1), lonToWindowX(lon2), latToWindowY(lat2));
  
  // draw line inside inset as well, using clip
  float insetX1 = lonToInsetX(lon1);
  float insetY1 = latToInsetY(lat1);
  float insetX2 = lonToInsetX(lon2);
  float insetY2 = latToInsetY(lat2);
  clip(insetLeft, insetTop, insetWidth, insetHeight);
  line(insetX1, insetY1, insetX2, insetY2);
  noClip();
}

void drawObservations() {
  stroke(0);
  strokeWeight(3);

  // Draw the features as simple points
  for (Observation obs : observations) {
    switch (obs.birdID) {
    case 166: 
      stroke(255, 0, 0); 
      break;
    case 167: 
      stroke(0, 0, 0); 
      break;
    default: 
      stroke(0, 0, 255); 
      break;
    }

    mappoint(obs.longitude, obs.latitude);
  }

  // Only draw once, no interactivity for this mode
  noLoop();
}

LocalDateTime now = LocalDateTime.of(2009, Month.JUNE, 29, 12, 00);
int[] birdCurrentIndex = new int[birdIDs.length];

void drawPaths() {
  stroke(0);
  strokeWeight(3);

  // Print the current time in the corner of the window
  textAlign(RIGHT, TOP);
  text(now.format(DateTimeFormatter.ISO_LOCAL_DATE_TIME), width - 280, height - 30);

  // Move forward in time
  now = now.plusMinutes(30);
  for (int i = 0; i < birdIDs.length; i++) {
    // Set the stroke to this bird's colour
    switch (birdIDs[i]) {
    case 166: 
      fill(255, 0, 0); 
      stroke(255, 0, 0); 
      break;
    case 167: 
      fill(0, 0, 0); 
      stroke(0, 0, 0); 
      break;
    default: 
      fill(0, 0, 255); 
      stroke(0, 0, 255); 
      break;
    }

    // Start a line at the current point
    double startLon = observations[birdCurrentIndex[i]].longitude;
    double startLat = observations[birdCurrentIndex[i]].latitude;
    mappoint(startLon, startLat);
    if (observations[birdCurrentIndex[i]].SA8 != null) {
      maptext(observations[birdCurrentIndex[i]].SA8, startLon, startLat);
    }

    // Is this observation still after the new value of "now"?
    if (observations[birdCurrentIndex[i]].date_time.isAfter(now)) {
      continue;
    }

    do {
      birdCurrentIndex[i]++;
    } while (observations[birdCurrentIndex[i]].birdID != birdIDs[i]);

    // Look for an observation in the future that is before "now", and draw
    // a line to it
    // TODO this throws an exception when the end of array is reached
    while (birdCurrentIndex[i] < observations.length) {
      mapline(startLon, startLat, 
        observations[birdCurrentIndex[i]].longitude, 
        observations[birdCurrentIndex[i]].latitude);
      startLon = observations[birdCurrentIndex[i]].longitude;
      startLat = observations[birdCurrentIndex[i]].latitude;

      if (observations[birdCurrentIndex[i]].SA8 != null) {
        maptext(observations[birdCurrentIndex[i]].SA8, startLon, startLat);
      }

      if (observations[birdCurrentIndex[i]].date_time.isAfter(now)) break;

      do {
        birdCurrentIndex[i]++;
      } while (observations[birdCurrentIndex[i]].birdID != birdIDs[i]);
    }
  }

  // Make sure the drawing loop is running, at a slow frame rate
  loop();
  frameRate(5);
}

int[] birdCurrentIndexForTrails = new int[birdIDs.length];
int[] birdNextIndexForTrails = new int[birdIDs.length];
int trailLength = 5;
double[][] birdTrailPointsLon = new double[birdIDs.length][trailLength];
double[][] birdTrailPointsLat = new double[birdIDs.length][trailLength];

void drawTrails() {
  stroke(0);
  strokeWeight(5);

  // Print the current time in the corner of the window
  textAlign(RIGHT, TOP);
  text(now.format(DateTimeFormatter.ISO_LOCAL_DATE_TIME), width - 280, height - 30);

  // Move forward in time
  now = now.plusMinutes(2);
  for (int i = 0; i < birdIDs.length; i++) {
    // Set the stroke to this bird's colour
    int r, g, b;
    switch (birdIDs[i]) {
      case 166: r = 255; g = 0; b = 0; break;
      case 167: r = 0; g = 0; b = 0; break;
      default: r = 0; g = 0; b = 255; break;
    }

    // Plot the bird's previous positions in a trail, and shift the trail
    // array contents back
    for (int j = 0; j < trailLength; j++) {
      stroke(r, g, b, (j + 1) * (j + 1) * 255 / (trailLength + 1) / (trailLength + 1));
      
      mappoint(birdTrailPointsLon[i][j], birdTrailPointsLat[i][j]);
      if (j > 0) {
        birdTrailPointsLon[i][j - 1] = birdTrailPointsLon[i][j];
        birdTrailPointsLat[i][j - 1] = birdTrailPointsLat[i][j];
      }
    }
    
    fill(r, g, b);
    stroke(r, g, b);

    long startTime = observations[birdCurrentIndexForTrails[i]].date_time.toEpochSecond(ZoneOffset.UTC);
    double startLon = observations[birdCurrentIndexForTrails[i]].longitude;
    double startLat = observations[birdCurrentIndexForTrails[i]].latitude;
    long endTime = observations[birdNextIndexForTrails[i]].date_time.toEpochSecond(ZoneOffset.UTC);
    double endLon = observations[birdNextIndexForTrails[i]].longitude;
    double endLat = observations[birdNextIndexForTrails[i]].latitude;
    
    // How far between the current and next point are we? (factor between 0 and 1)
    double lambda;
    if (endTime == startTime) {
      lambda = 0;
    } else {
      lambda = (double)(now.toEpochSecond(ZoneOffset.UTC) - startTime) / (endTime - startTime);
    }
    double thisLon = startLon + (endLon - startLon) * lambda;
    double thisLat = startLat + (endLat - startLat) * lambda;
    
    // Plot the bird's current position
    mappoint(thisLon, thisLat);
    if (observations[birdCurrentIndexForTrails[i]].SA8 != null) {
      maptext(observations[birdCurrentIndexForTrails[i]].SA8, thisLon, thisLat);
    }
    
    // Store this point for the next point's trail
    birdTrailPointsLon[i][trailLength - 1] = thisLon;
    birdTrailPointsLat[i][trailLength - 1] = thisLat;

    // Is this observation still after the new value of "now"?
    if (observations[birdCurrentIndexForTrails[i]].date_time.isAfter(now)) {
      continue;
    }
    
    // Next point becomes current point
    System.arraycopy(birdNextIndexForTrails, 0, birdCurrentIndexForTrails, 0, birdIDs.length);

    // Look for the next observation for this bird
    do {
      birdNextIndexForTrails[i]++;
    } while (observations[birdNextIndexForTrails[i]].birdID != birdIDs[i]);

    // Look for an observation in the future that is after "now"
    // TODO this throws an exception when the end of array is reached
    while (!observations[birdNextIndexForTrails[i]].date_time.isAfter(now)) {
      do {
        birdNextIndexForTrails[i]++;
      } while (observations[birdNextIndexForTrails[i]].birdID != birdIDs[i]);
    }
  }

  // Make sure the drawing loop is running, with a high frame rate
  loop();
  frameRate(20);
}

// Called when a UI button is clicked.
void buttonClicked(Button b) {
  if (b == button1) {
    currentMode = Mode.OBSERVATIONS;
  } else if (b == button2) {
    currentMode = Mode.PATHS;
  } else if (b == button3) {
    currentMode = Mode.TRAILS;
  }

  draw();
}

// Reads data from the given tab-separated text file and stores it in an attribute map.
Observation[] loadObservationData(String fileName) {
  ArrayList<Observation> observationsList = new ArrayList<Observation>();

  String[] rows = loadStrings(fileName);
  String[] columnHeaders = null;
  DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

  for (String row : rows) {
    String[] columns = row.split("\t");

    // If this is the first row, store the column header names.
    if (columnHeaders == null) {
      columnHeaders = columns;
      continue;
    }

    if (columns.length >= 2) {
      Observation obs = new Observation();

      // Assign values from the columns into the observation object
      for (int i = 0; i < columns.length; i++) {
        switch (columnHeaders[i]) {
        case "birdID": 
          obs.birdID = Integer.parseInt(columns[i]); 
          break;
        case "date_time": 
          obs.date_time = LocalDateTime.parse(columns[i], formatter); 
          break;
        case "latitude": 
          obs.latitude = Double.parseDouble(columns[i]); 
          break;
        case "longitude": 
          obs.longitude = Double.parseDouble(columns[i]); 
          break;
        case "SA8": 
          obs.SA8 = columns[i]; 
          break;
        }
      }

      observationsList.add(obs);
    }
  }

  return observationsList.toArray(new Observation[0]);
}

class Observation {
  int birdID;
  LocalDateTime date_time;
  double latitude;
  double longitude;
  // lots of other fields go here...
  String SA8;
}
