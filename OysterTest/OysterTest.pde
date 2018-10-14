import controlP5.*;

import java.time.*;
import java.time.format.*;
import de.bezier.guido.*;

ControlP5 cp5;
CColor controlsColours;

int speed = 5;
class Observation {
  int birdID;
  LocalDateTime date_time;
  double latitude;
  double longitude;
  // lots of other fields go here...
  String SA8;
}

// Bird observations
Observation[] observations;
// The three birds in the dataset (hard-coded to save effort)
int[] birdIDs = { 166, 167, 169 };

// SVG basemap
PShape basemap;
// The geographic extents of the SVG basemap
float[] basemapExtents = { 6.190, 53.427, 6.280, 53.490 };

// UI elements
Button button1, button2, button3;
CheckBox[] chkBirds;
CheckBox chkStateBodyCare, chkStateFly, chkStateForage,
  chkStateSit, chkStateStand, chkStateUnknown;

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
// not be exactly reversible.
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

// And back the other way, from window position to lat/long.
double windowXToLon(float x) {
  return (basemapExtents[2] - basemapExtents[0]) * (double)x / width + basemapExtents[0];
}
double windowYToLat(float y) {
  return (basemapExtents[3] - basemapExtents[1]) * ((double)(height - 1) - (double)y) /
    height + basemapExtents[1];
}
double insetXToLon(float x) {
  return windowXToLon((x - insetBasemapExtents[0]) / insetMagnification);
}
double insetYToLat(float y) {
  return windowYToLat((y - insetBasemapExtents[1]) / insetMagnification);
}

void setup() {
  // Load the basemap
  basemap = loadShape("basemap.svg");

  // Load the point data
  observations = loadObservationData("All data.txt");

  // Set up the dimensions of an inset to magnify the nesting area
  insetWidth = 300;
  insetHeight = 270;
  insetLeft = 20;
  insetTop = height - insetHeight - 20;

  // Set up the UI
  Interactive.make(this);

  button1 = new Button("Observations", width - 270, height - 36, 80, 26);
  Interactive.on(button1, "click", this, "buttonClicked");

  button2 = new Button("Paths", width - 180, height - 36, 80, 26);
  Interactive.on(button2, "click", this, "buttonClicked");

  button3 = new Button("Trails", width - 90, height - 36, 80, 26);
  Interactive.on(button3, "click", this, "buttonClicked");

  chkBirds = new CheckBox[3];
  chkBirds[0] = new CheckBox("Bird 166", insetWidth + 40, height - 20 - CheckBox.size);
  chkBirds[0].highlightColor = birdColor(166);
  chkBirds[0].checked = true;

  chkBirds[1] = new CheckBox("Bird 167", insetWidth + 140, height - 20 - CheckBox.size);
  chkBirds[1].highlightColor = birdColor(167);
  chkBirds[1].checked = true;

  chkBirds[2] = new CheckBox("Bird 169", insetWidth + 240, height - 20 - CheckBox.size);
  chkBirds[2].highlightColor = birdColor(169);
  chkBirds[2].checked = true;
  
  chkStateBodyCare = new CheckBox("Body care", insetWidth + 40, height - 45 - CheckBox.size);
  chkStateBodyCare.checked = true;
  chkStateFly = new CheckBox("Fly", insetWidth + 135, height - 45 - CheckBox.size);
  chkStateFly.checked = true;
  chkStateForage = new CheckBox("Forage", insetWidth + 190, height - 45 - CheckBox.size);
  chkStateForage.checked = true;
  chkStateSit = new CheckBox("Sit", insetWidth + 265, height - 45 - CheckBox.size);
  chkStateSit.checked = true;
  chkStateStand = new CheckBox("Stand", insetWidth + 320, height - 45 - CheckBox.size);
  chkStateStand.checked = true;
  chkStateUnknown = new CheckBox("Unknown", insetWidth + 395, height - 45 - CheckBox.size);
  chkStateUnknown.checked = true;
  
  // Calculate the magnification level and basemap extents of the inset
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

  setupObservationsMode();
  
  //add speed control slider
  controlsColours = new CColor(0x99ffffff, 0x55ffffff, 0xffffffff, 0xffffffff, 0xffffffff);
  cp5 = new ControlP5(this);
    cp5.addSlider("speed")
   .setPosition(20,250)
   .setSize(20,100)
   .setRange(1,30)
   .setNumberOfTickMarks(30)
   .setColor(controlsColours)
   ;
}

void settings() {
  size((int)(800 * (basemapExtents[2] - basemapExtents[0]) /
    (basemapExtents[3] - basemapExtents[1])), 800);
}

void draw() {
  // Draw the basemap to fill the entire window
  shape(basemap, 0, 0, width, height);

  // Label the scale bar
  fill(0);
  textAlign(CENTER, BOTTOM);
  text("0", 22, 26);
  text("250", 69, 26);
  text("500", 114, 26);
  text("m", 134, 26);

  // Draw a magnification of the nesting area
  drawInsetMap();

  switch (currentMode) {
  case OBSERVATIONS: 
    drawObservations(); 
    cp5.getController("speed").setVisible(false);
    break;
  case PATHS: 
    drawPaths(); 
    cp5.getController("speed").setVisible(true);
    break;
  case TRAILS:
    drawTrails();
    cp5.getController("speed").setVisible(true);
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

// Used to reject mouse events that lie inside a UI element.
boolean isInsideUIElement() {
  return
   (button1.isInside(mouseX, mouseY) ||
    button2.isInside(mouseX, mouseY) ||
    button3.isInside(mouseX, mouseY));    
}

// Glue logic for various UI events.
void mousePressed() {
  // Skip the event if we're inside any of the UI elements.
  if (isInsideUIElement()) {
    return;
  }

  switch (currentMode) {
  case OBSERVATIONS: 
    observationsMousePressed(); 
    break;
  default:
    break;
  }
}

void mouseReleased() {
  switch (currentMode) {
  case OBSERVATIONS: 
    observationsMouseReleased(); 
    break;
  default:
    break;
  }
}

int pathspeed = 30;
int trailspeed = 2;

// Called when a UI button is clicked.
void buttonClicked(Button b) { 
  if (b == button1) {
    currentMode = Mode.OBSERVATIONS;
    enterObservationsMode();
  } else if (b == button2) {
    if (currentMode == Mode.PATHS)
    {
     if (pathspeed == 30){
       pathspeed = 0;} else {
         pathspeed = 30;}
    } else {
      pathspeed = 30;
    }
    currentMode = Mode.PATHS;
  } else if (b == button3) {
    if (currentMode == Mode.TRAILS)
    {
     if (trailspeed == 2){
       trailspeed = 0;} else {
         trailspeed = 2;}
    } else {
      trailspeed = 2;
    }
    currentMode = Mode.TRAILS;
  }
  
  // Show/hide observation mode checkboxes
  chkStateBodyCare.visible = chkStateFly.visible = chkStateForage.visible =
    chkStateSit.visible = chkStateStand.visible = chkStateUnknown.visible =
    currentMode == Mode.OBSERVATIONS;

  draw();
}

color birdColor(int birdID) {
  switch (birdID) {
    case 166: 
      return color(255, 0, 0); 
    case 167: 
      return color(0, 0, 0); 
    default: 
      return color(0, 0, 255); 
  }
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

// Is the given location inside the inset?
boolean isInsideInset(float mx, float my) {
  return mx >= insetLeft && mx <= insetLeft + insetWidth &&
    my >= insetTop && my <= insetTop + insetHeight;
}

LocalDateTime now = LocalDateTime.of(2009, Month.JUNE, 29, 12, 00);

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
