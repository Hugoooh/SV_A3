// The window coordinates where the drag began
float initialDragX, initialDragY;

// The bounds of the focus area in window coordinates
float[] focusBounds = null;

// Is the focus area inside the inset map?
boolean isFocusInInset = false;

// Dimensions of the graph box
float graphX, graphY, graphWidth, graphHeight;

// Shapes drawn as part of the graph's y-axis
PShape sun, moon;

// Called as part of the global setup() function.
void setupObservationsMode() {
  sun = loadShape("glyph-sun.svg");
  moon = loadShape("glyph-moon.svg");
      
  graphX = width - 420;
  graphY = height - 350;
  graphWidth = 400;
  graphHeight = 250;
}

// Called when the user enters observation mode.
void enterObservationsMode() {
  initialDragX = initialDragY = -1;
  focusBounds = null;
}

void drawObservations() {
  stroke(0);
  strokeWeight(3);

  // Draw the features as simple points
  for (Observation obs : observations) {
    if (!obsVisible(obs)) {
      continue;
    }
    
    stroke(birdColor(obs.birdID));

    mappoint(obs.longitude, obs.latitude);
  }

  // Draw the dragging rectangle if the mouse is pressed
  if (mousePressed && initialDragX >= 0) {
    fill(0, 30);
    stroke(0, 200);
    strokeWeight(1);
    
    // If the drag began inside the inset, we need to clip the
    // drag rectangle to the inset
    if (isFocusInInset) {
      clip(insetLeft, insetTop, insetWidth, insetHeight);
    }
    
    rect(initialDragX, initialDragY, mouseX - initialDragX, mouseY - initialDragY);
    
    noClip();
  }
  // Otherwise, if a focus area has been chosen, draw the
  // rectangle over this area as well as a statistical box (graph)
  else if (focusBounds != null) {
    fill(0, 120, 20, 30);
    stroke(0, 120, 20, 200);
    strokeWeight(1);
    rect(focusBounds[0], focusBounds[1], focusBounds[2], focusBounds[3]);
    
    fill(255);
    stroke(0);
    rect(graphX, graphY, graphWidth, graphHeight);
    
    // Get the visible observations that relate to the selected area
    double focusMinLon, focusMaxLon, focusMinLat, focusMaxLat;
    if (isFocusInInset) {
      focusMinLon = insetXToLon(focusBounds[0]);
      focusMaxLon = insetXToLon(focusBounds[0] + focusBounds[2]);
      focusMinLat = insetYToLat(focusBounds[1] + focusBounds[3]);
      focusMaxLat = insetYToLat(focusBounds[1]);
    } else {
      focusMinLon = windowXToLon(focusBounds[0]);
      focusMaxLon = windowXToLon(focusBounds[0] + focusBounds[2]);
      focusMinLat = windowYToLat(focusBounds[1] + focusBounds[3]);
      focusMaxLat = windowYToLat(focusBounds[1]);
    }
    
    ArrayList<Observation> theseObs = new ArrayList<Observation>();
    int[] obsPerBird = new int[birdIDs.length];
    for (Observation obs : observations) { 
      if (obs.longitude >= focusMinLon && obs.longitude <= focusMaxLon &&
        obs.latitude >= focusMinLat && obs.latitude <= focusMaxLat &&
        obsVisible(obs)
      ) {
        theseObs.add(obs);
        
        if (obs.birdID == 166) {
          obsPerBird[0]++;
        } else if (obs.birdID == 167) {
          obsPerBird[1]++;
        } else {
          obsPerBird[2]++;
        }
      }
    }
    
    drawGraph(theseObs, obsPerBird);
    
    noLoop();
  } else {
    noLoop();
  }
  
  // Put a label at the bottom explaining that dragging is possible
  fill(0);
  textAlign(LEFT, BOTTOM);
  text("Draw a box to show statistics for an area", insetWidth + 40, height - 93);
}

//Draw the graph based on selected area on button-right
void drawGraph(ArrayList<Observation> theseObs, int[] obsPerBird) {
  // Print number of observations
  fill(0);
  textAlign(LEFT, TOP);
  text(String.format("n = %d    (bird 166 = %d,  bird 167 = %d,  bird 169 = %d)",
    theseObs.size(), obsPerBird[0], obsPerBird[1], obsPerBird[2]), graphX + 10, graphY + 10);
  
  // Figure out the bounds of the actual plot area
  float plotAreaLeft = graphX + 50;
  float plotAreaWidth = graphWidth - 70; // 50 on left, 20 on right
  float plotAreaTop = graphY + 40;
  float plotAreaBottom = graphY + graphHeight - 40;
  
  // Print x-axis and the label of x-axis
  line(plotAreaLeft, plotAreaBottom, plotAreaLeft + plotAreaWidth, plotAreaBottom);
  textAlign(CENTER, TOP);
  text("stand",     plotAreaLeft + plotAreaWidth / 12,      plotAreaBottom + 10);
  text("sit",       plotAreaLeft + plotAreaWidth * 3 / 12,  plotAreaBottom + 10);
  text("forage",    plotAreaLeft + plotAreaWidth * 5 / 12,  plotAreaBottom + 10);
  text("body care", plotAreaLeft + plotAreaWidth * 7 / 12,  plotAreaBottom + 10);
  text("fly",       plotAreaLeft + plotAreaWidth * 9 / 12,  plotAreaBottom + 10);
  text("unknown",   plotAreaLeft + plotAreaWidth * 11 / 12, plotAreaBottom + 10);
  
  // Print y-axis, vertical gridlines, and y-axis labels
  line(plotAreaLeft, plotAreaTop, plotAreaLeft, plotAreaBottom);
  for (int i = 1; i <= 6; i++) {
    line(plotAreaLeft + plotAreaWidth * i / 6, plotAreaBottom,
      plotAreaLeft + plotAreaWidth * i / 6, plotAreaTop);
  }
  textSideways("Time of day", plotAreaLeft - 40, graphY + graphHeight / 2);
  
  textAlign(LEFT, CENTER);
  shape(moon, plotAreaLeft - 21, plotAreaTop + 10, 16, 16);
  text("am",  plotAreaLeft - 21, plotAreaTop + (graphHeight - 80) / 4);
  shape(sun,  plotAreaLeft - 21, plotAreaTop + (graphHeight - 80) / 2 - 8, 16, 16);
  text("pm",  plotAreaLeft - 21, plotAreaTop + (graphHeight - 80) * 3 / 4 - 10);
  shape(moon, plotAreaLeft - 21, plotAreaTop + (graphHeight - 80) - 26, 16, 16);
  
  // Plot points on graph according to its' state and time record
  for (Observation obs : theseObs) {
    strokeWeight(3);
    stroke(birdColor(obs.birdID));
    
    // X-axis is behaviours
    // plot points to each area according to obs.SA8
    float plotX = plotAreaLeft;
    if (obs.SA8 != null) {
      switch (obs.SA8) {
        case "stand":     plotX += plotAreaWidth / 12;     break;
        case "sit":       plotX += plotAreaWidth * 3 / 12; break;
        case "forage":    plotX += plotAreaWidth * 5 / 12; break;
        case "body care": plotX += plotAreaWidth * 7 / 12; break;
        case "fly":       plotX += plotAreaWidth * 9 / 12; break;
      }
    } else {
      plotX += plotAreaWidth * 11 / 12;
    }
    // Add in "randomness" to the X-coordinate (actually deterministic)
    plotX += 1234577 * obs.date_time.toEpochSecond(ZoneOffset.UTC) % 50 - 25;
    
    // Y-axis is times of day
    float plotY = plotAreaTop;
    long minutes = obs.date_time.getHour() * 60 + obs.date_time.getMinute();
    // add 25 minutes for solar time (observations are in UTC, Schiermonnikoog
    // is a bit east of the meridian)
    // TODO this conversion needs to apply to all modes
    minutes += 25; 
    if (minutes >= 24 * 60) {
      minutes -= 24 * 60; 
    }
    plotY += ((float)minutes / 60) * (plotAreaBottom - plotAreaTop) / 24;
     
    point(plotX, plotY);
  }
}

// function to manage the text
void textSideways(String text, float x, float y) {
  pushMatrix();
  translate(x, y);
  rotate(-HALF_PI);
  translate(-x, -y);
  text(text, x, y);
  popMatrix();
}

// Should this observation be shown to the user?
// check the birdid, month and state
boolean obsVisible(Observation obs) {
  if (!chkBirds[obs.birdID == 166 ? 0 : (obs.birdID == 167 ? 1 : 2)].checked) {
    return false;
  }
  
  switch (obs.month){
    case "JUNE": if (!chkJune.checked) return false; break;
    case "JULY": if (!chkJuly.checked) return false; break;
    case "AUGUST": if (!chkAugust.checked) return false; break;
    case "SEPTEMBER": if (!chkSeptember.checked) return false; break;
    default: if (!chkLater.checked) return false; break;
  }
  
  if (obs.SA8 == null) {
    return chkStateUnknown.checked;
  }
  
  switch (obs.SA8) {
    case "body care": return chkStateBodyCare.checked;
    case "fly": return chkStateFly.checked;
    case "forage": return chkStateForage.checked;
    case "sit": return chkStateSit.checked;
    case "stand": return chkStateStand.checked;
  }
  
  return true;
}

// Called when the mouse is pressed; initiates dragging.
void observationsMousePressed() {
  initialDragX = mouseX;
  initialDragY = mouseY;
  
  // Is the dragging taking place in the inset?
  isFocusInInset = isInsideInset(initialDragX, initialDragY);
  
  // Start the drawing loop
  frameRate(60);
  loop();
}

// Called when the mouse is released; sets down the area over which statistical
// calculations should be performed.
void observationsMouseReleased() {
  // Have we just entered this mode?
  if (initialDragX < 0) {
    return;
  }
  
  // Set the window bounds of the focus rectangle
  focusBounds = new float[] {
    min(initialDragX, mouseX),
    min(initialDragY, mouseY),
    abs(mouseX - initialDragX),
    abs(mouseY - initialDragY)
  };
  
  // If the drag began inside the inset, clamp the rectangle to
  // the inset bounds.
  if (isFocusInInset) {
    if (insetLeft > focusBounds[0]) {
      focusBounds[2] -= insetLeft - focusBounds[0];
      focusBounds[0] = insetLeft;
    }
    if (insetTop > focusBounds[1]) {
      focusBounds[3] -= insetTop - focusBounds[1];
      focusBounds[1] = insetTop;
    }
    focusBounds[2] = min(insetLeft + insetWidth - focusBounds[0] - 1, focusBounds[2]);
    focusBounds[3] = min(insetTop + insetHeight - focusBounds[1] - 1, focusBounds[3]);
  }
  
  // If the focus area is too small, clear it.
  if (focusBounds[2] < 2 && focusBounds[3] < 2) {
    focusBounds = null;
  }
}
