int[] birdCurrentIndex = new int[birdIDs.length];

void drawPaths() {
  stroke(0);
  strokeWeight(3);

  // Print the current time in the corner of the window
  textAlign(RIGHT, TOP);
  text(now.format(DateTimeFormatter.ISO_LOCAL_DATE_TIME), width - 370, height - 30);
  

  
  // Label the "speed" slider
  textAlign(LEFT, BOTTOM);
  text("Speed (fps)", insetWidth + 31, height - 160);

  // Move forward in time
  now = now.plusMinutes(pathspeed);
  for (int i = 0; i < birdIDs.length; i++) {    
    // Set the stroke to this bird's colour
    fill(birdColor(birdIDs[i]));
    stroke(birdColor(birdIDs[i]));

    // Start a line at the current point
    double startLon = observations[birdCurrentIndex[i]].longitude;
    double startLat = observations[birdCurrentIndex[i]].latitude;
    if (chkBirds[i].checked) {
      mappoint(startLon, startLat);
      if (observations[birdCurrentIndex[i]].SA8 != null) {
        maptext(observations[birdCurrentIndex[i]].SA8, startLon, startLat);
      }
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
      if (chkBirds[i].checked) {
        mapline(startLon, startLat, 
          observations[birdCurrentIndex[i]].longitude, 
          observations[birdCurrentIndex[i]].latitude);
        startLon = observations[birdCurrentIndex[i]].longitude;
        startLat = observations[birdCurrentIndex[i]].latitude;
  
        if (observations[birdCurrentIndex[i]].SA8 != null) {
          maptext(observations[birdCurrentIndex[i]].SA8, startLon, startLat);
        }
      }

      if (observations[birdCurrentIndex[i]].date_time.isAfter(now)) break;

      do {
        birdCurrentIndex[i]++;
      } while (observations[birdCurrentIndex[i]].birdID != birdIDs[i]);
    }
  }

  // Make sure the drawing loop is running, at a slow frame rate
  loop();
  frameRate(speed);
}
