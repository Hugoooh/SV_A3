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
Button button1, button2;

// Available modes
enum Mode {
  OBSERVATIONS, PATHS
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

void setup() {
  // Load the basemap
  basemap = loadShape("basemap.svg");
  
  // Load the point data
  observations = loadObservationData("All data.txt");
  
  // Set up the UI
  Interactive.make(this);
  
  button1 = new Button("Observations", width - 180, height - 36, 80, 26);
  Interactive.on(button1, "click", this, "buttonClicked");
 
  button2 = new Button("Paths", width - 90, height - 36, 80, 26);
  Interactive.on(button2, "click", this, "buttonClicked");
  
  frameRate(5);
}

void settings() {
  size((int)(800 * (basemapExtents[2] - basemapExtents[0]) /
    (basemapExtents[3] - basemapExtents[1])), 800);
}

void draw() {
  // Draw the basemap to fill the entire window (for now)
  shape(basemap, 0, 0, width, height);
  
  // Draw a magnification of the nesting area
  clip(20, height - 320, 300, 300);
  shape(basemap, -1600, -1600, width * 8, height * 8);
  noFill();
  rect(20, height - 320, 299, 299);
  textAlign(CENTER, CENTER);
  text("enlargement of nesting area\nwill go here", 150, height - 150);
  noClip();
  
  switch (currentMode) {
    case OBSERVATIONS: drawObservations(); break;
    case PATHS: drawPaths(); break;
  }
}

void drawObservations() {
  stroke(0);
  strokeWeight(3);

  // Draw the features as simple points
  for (Observation obs : observations) {
    switch (obs.birdID) {
      case 166: stroke(255,0,0); break;
      case 167: stroke(0,0,0); break;
      default: stroke(0,0,255); break;
    }
    
    point(lonToWindowX(obs.longitude), latToWindowY(obs.latitude));
  }
  
  // Only draw once, no interactivity for this mode
  noLoop();
}

LocalDateTime now = LocalDateTime.of(2009, Month.JUNE, 29, 12, 00);
int[] birdCurrentIndex = new int[birdIDs.length];

void drawPaths() {
  stroke(0);
  strokeWeight(3);
    
  textAlign(RIGHT, TOP);
  text(now.format(DateTimeFormatter.ISO_LOCAL_DATE_TIME), width - 190, height - 30);
  
  // Move forward in time
  now = now.plusMinutes(30);
  for (int i = 0; i < birdIDs.length; i++) {
    // Set the stroke to this bird's colour
    switch (birdIDs[i]) {
      case 166: fill(255,0,0); stroke(255,0,0); break;
      case 167: fill(0,0,0); stroke(0,0,0); break;
      default: fill(0,0,255); stroke(0,0,255); break;
    }
    
    // Start a line at the current point
    float startX = lonToWindowX(observations[birdCurrentIndex[i]].longitude);
    float startY = latToWindowY(observations[birdCurrentIndex[i]].latitude);
    point(startX, startY);
    if (observations[birdCurrentIndex[i]].SA8 != null) {
      //text(observations[birdCurrentIndex[i]].SA8, startX, startY);
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
      line(startX, startY,
        lonToWindowX(observations[birdCurrentIndex[i]].longitude),
        latToWindowY(observations[birdCurrentIndex[i]].latitude));
      startX = lonToWindowX(observations[birdCurrentIndex[i]].longitude);
      startY = latToWindowY(observations[birdCurrentIndex[i]].latitude);
      
      if (observations[birdCurrentIndex[i]].SA8 != null) {
        text(observations[birdCurrentIndex[i]].SA8, startX, startY);
      }
      
      if (observations[birdCurrentIndex[i]].date_time.isAfter(now)) break;
      
      do {
        birdCurrentIndex[i]++;
      } while (observations[birdCurrentIndex[i]].birdID != birdIDs[i]);
    }
  }
  
  // Make sure the drawing loop is running
  loop();
}

// Called when a UI button is clicked.
void buttonClicked(Button b) {
  if (b == button1) {
    currentMode = Mode.OBSERVATIONS;
  } else if (b == button2) {
    currentMode = Mode.PATHS;
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
          case "birdID": obs.birdID = Integer.parseInt(columns[i]); break;
          case "date_time": obs.date_time = LocalDateTime.parse(columns[i], formatter); break;
          case "latitude": obs.latitude = Double.parseDouble(columns[i]); break;
          case "longitude": obs.longitude = Double.parseDouble(columns[i]); break;
          case "SA8": obs.SA8 = columns[i]; break;
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
