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
  now = now.plusMinutes(trailspeed);
  for (int i = 0; i < birdIDs.length; i++) {
    color thisColor = birdColor(birdIDs[i]);
    
    // Plot the bird's previous positions in a trail, and shift the trail
    // array contents back
    for (int j = 0; j < trailLength; j++) {
      stroke(thisColor, (j + 1) * (j + 1) * 255 / (trailLength + 1) / (trailLength + 1));
      
      if (chkBirds[i].checked) {
        mappoint(birdTrailPointsLon[i][j], birdTrailPointsLat[i][j]);
      }
      
      if (j > 0) {
        birdTrailPointsLon[i][j - 1] = birdTrailPointsLon[i][j];
        birdTrailPointsLat[i][j - 1] = birdTrailPointsLat[i][j];
      }
    }
    
    fill(thisColor);
    stroke(thisColor);

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
    if (chkBirds[i].checked) {
      mappoint(thisLon, thisLat);
      if (observations[birdCurrentIndexForTrails[i]].SA8 != null) {
        maptext(observations[birdCurrentIndexForTrails[i]].SA8, thisLon, thisLat);
      }
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
  frameRate(speed*4);
}
