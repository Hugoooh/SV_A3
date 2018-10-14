float initialDragX, initialDragY;

// The extents of the focus area in window coordinates
float[] focusExtents = null;

// Is the focus area inside the inset map?
boolean isFocusInInset = false;

float graphX, graphY, graphWidth, graphHeight;

PShape sun, moon;

void setupObservationsMode() {
  sun = loadShape("glyph-sun.svg");
  moon = loadShape("glyph-moon.svg");
}

void enterObservationsMode() {
  initialDragX = initialDragY = -1;
  focusExtents = null;
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
  else if (focusExtents != null) {
    fill(0, 120, 20, 30);
    stroke(0, 120, 20, 200);
    strokeWeight(1);
    rect(focusExtents[0], focusExtents[1], focusExtents[2], focusExtents[3]);
    
    graphX = width - 420;
    graphY = height - 350;
    graphWidth = 400;
    graphHeight = 250;
    
    fill(255);
    stroke(0);
    rect(graphX, graphY, graphWidth, graphHeight);
    
    // Get the visible observations that relate to this area
    double focusMinLon, focusMaxLon, focusMinLat, focusMaxLat;
    if (isFocusInInset) {
      focusMinLon = insetXToLon(focusExtents[0]);
      focusMaxLon = insetXToLon(focusExtents[0] + focusExtents[2]);
      focusMinLat = insetYToLat(focusExtents[1] + focusExtents[3]);
      focusMaxLat = insetYToLat(focusExtents[1]);
    } else {
      focusMinLon = windowXToLon(focusExtents[0]);
      focusMaxLon = windowXToLon(focusExtents[0] + focusExtents[2]);
      focusMinLat = windowYToLat(focusExtents[1] + focusExtents[3]);
      focusMaxLat = windowYToLat(focusExtents[1]);
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
    
    // Print number of observations
    fill(0);
    textAlign(LEFT, TOP);
    text(String.format("n = %d    (bird 166 = %d,  bird 167 = %d,  bird 169 = %d)",
      theseObs.size(), obsPerBird[0], obsPerBird[1], obsPerBird[2]), graphX + 10, graphY + 10);
    
    // Print x-axis
    line(graphX + 50, graphY + graphHeight - 40,
      graphX + graphWidth - 20, graphY + graphHeight - 40);
    textAlign(CENTER, TOP);
    text("stand",     graphX + 50 + (graphWidth - 70) / 12,      graphY + graphHeight - 30);
    text("sit",       graphX + 50 + (graphWidth - 70) * 3 / 12,  graphY + graphHeight - 30);
    text("forage",    graphX + 50 + (graphWidth - 70) * 5 / 12,  graphY + graphHeight - 30);
    text("body care", graphX + 50 + (graphWidth - 70) * 7 / 12,  graphY + graphHeight - 30);
    text("fly",       graphX + 50 + (graphWidth - 70) * 9 / 12,  graphY + graphHeight - 30);
    text("unknown",   graphX + 50 + (graphWidth - 70) * 11 / 12, graphY + graphHeight - 30);
    
    // Print y-axis, vertical gridlines, and y-axis labels
    line(graphX + 50, graphY + graphHeight - 40, graphX + 50, graphY + 40);
    for (int i = 1; i <= 6; i++) {
      line(graphX + 50 + (graphWidth - 70) * i / 6, graphY + graphHeight - 40,
        graphX + 50 + (graphWidth - 70) * i / 6, graphY + 40);
    }
    textSideways("Time of day", graphX + 10, graphY + graphHeight / 2);
    
    textAlign(LEFT, CENTER);
    shape(moon, graphX + 29, graphY + 40 + 10, 16, 16);
    text("am", graphX + 29, graphY + 40 + (graphHeight - 80) / 4);
    shape(sun, graphX + 29, graphY + 40 + (graphHeight - 80) / 2 - 8, 16, 16);
    text("pm", graphX + 29, graphY + 40 + 3 * (graphHeight - 80) / 4 - 10);
    shape(moon, graphX + 29, graphY + 40 + (graphHeight - 80) - 26, 16, 16);
    
    // Plot points on graph
    for (Observation obs : theseObs) {
      strokeWeight(3);
      stroke(birdColor(obs.birdID));
      
      // X-axis is behaviours
      float plotX = graphX + 50;
      if (obs.SA8 != null) {
        switch (obs.SA8) {
          case "stand":     plotX += (graphWidth - 70) / 12;     break;
          case "sit":       plotX += (graphWidth - 70) * 3 / 12; break;
          case "forage":    plotX += (graphWidth - 70) * 5 / 12; break;
          case "body care": plotX += (graphWidth - 70) * 7 / 12; break;
          case "fly":       plotX += (graphWidth - 70) * 9 / 12; break;
        }
      } else {
        plotX += (graphWidth - 70) * 11 / 12;
      }
      // Add in "randomness" (actually deterministic)
      plotX += 1234577 * obs.date_time.toEpochSecond(ZoneOffset.UTC) % 50 - 25;
      
      // Y-axis is times of day
      float plotY = graphY + 40;
      long minutes = obs.date_time.getHour() * 60 + obs.date_time.getMinute();
      // add 25 minutes for solar time (observations are in UTC, Schiermonnikoog
      // is a bit east of the meridian)
      // TODO this conversion needs to apply to all modes
      minutes += 25; 
      if (minutes >= 24 * 60) {
        minutes -= 24 * 60; 
      }
      plotY += ((float)minutes / 60) * (graphHeight - 80) / 24;
       
      point(plotX, plotY);
    }
    
    noLoop();
  } else {
    noLoop();
  }
  
  // Put a label at the bottom explaining that dragging is possible
  fill(0);
  textAlign(LEFT, BOTTOM);
  text("Draw a box to show statistics for an area", insetWidth + 40, height - 93);
}

void textSideways(String text, float x, float y) {
  pushMatrix();
  translate(x, y);
  rotate(-HALF_PI);
  translate(-x, -y);
  text(text, x, y);
  popMatrix();
}

// Should this observation be shown to the user?
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

// Called when the mouse is released; calculates statistical information
// for the selected observations.
void observationsMouseReleased() {
  // Have we just entered this mode?
  if (initialDragX < 0) {
    return;
  }
  
  // Set the window extents of the focus rectangle
  focusExtents = new float[] {
    min(initialDragX, mouseX),
    min(initialDragY, mouseY),
    abs(mouseX - initialDragX),
    abs(mouseY - initialDragY)
  };
  
  // If the drag began inside the inset, clamp the rectangle to
  // the inset extents.
  if (isFocusInInset) {
    if (insetLeft > focusExtents[0]) {
      focusExtents[2] -= insetLeft - focusExtents[0];
      focusExtents[0] = insetLeft;
    }
    if (insetTop > focusExtents[1]) {
      focusExtents[3] -= insetTop - focusExtents[1];
      focusExtents[1] = insetTop;
    }
    focusExtents[2] = min(insetLeft + insetWidth - focusExtents[0] - 1, focusExtents[2]);
    focusExtents[3] = min(insetTop + insetHeight - focusExtents[1] - 1, focusExtents[3]);
  }
  
  // If the focus area is too small, clear it.
  if (focusExtents[2] < 2 && focusExtents[3] < 2) {
    focusExtents = null;
  }
}
