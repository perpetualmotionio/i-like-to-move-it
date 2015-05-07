import ddf.minim.*;
import ddf.minim.analysis.*;

import SimpleOpenNI.*;

AudioVisualization audVis;
SimpleOpenNI kinect;
Minim minim;
AudioPlayer player;
FFT fft;

int kinIndex, dispIndex;
int index;
PImage img;
PImage newImg;

color[] appleNeonColors = {
  color(33,121,255), // neon blue
  color(118,185,0),  // puke green
  color(223,153,0),  // yellow
  color(212,41,66),  // hot pink
};

int currIndex = 0;
float currIndexTime = 0;
int timer = 0;

void setup() {

  size(640, 480);
  currIndexTime = getRandomTime(5000, 15000);
  setupKinect();

  audVis = new AudioVisualization();
  newImg = new PImage(width, height);
  img = new PImage(width, height);
  minim = new Minim(this);

  player = minim.loadFile("song.mp3", 512);
  player.play();

  fft = new FFT(player.bufferSize(), player.sampleRate());
  background(0);

  for (int i=0; i<1000; i++) {
    fill(229, 107, 7, random(10, 255));
    ellipse(random(0, width), random(0, height), 4, 4);
  }
  loadPixels();

  for (int x=0; x<width; x++) {
    for (int y=0; y<height; y++) {
      index=x+y*width;
      img.pixels[index]= pixels[index];
    }
  }
  img.updatePixels();
}

void setupKinect() {
  kinect = new SimpleOpenNI(this);
  if (false == kinect.isInit()) {
     println("Kinect can't be initialized!");
     exit();
     return;
  }

  kinect.setMirror(true);
  kinect.enableDepth();
  kinect.enableUser();
}

float getRandomTime(int minTime, int maxTime) {
  return random(minTime, maxTime);
}

void draw() {
  background(img);
  audVis.draw();
  kinect.update();

  loadPixels();
  updatePixels();

  int[] userVals = kinect.userMap();

  for (int x=0; x < width; x++) {
    for (int y=0; y < height; y++) {
      kinIndex = x + (y * width);
      dispIndex = width - x - 1 + (y * width);

      if (null != userVals && userVals[kinIndex] != 0) {
        newImg.pixels[dispIndex] = pixels[dispIndex];
      }
      else {
        newImg.pixels[dispIndex] = appleNeonColors[currIndex];
      }
    }
  }

  if (millis() - timer >= currIndexTime) {
    currIndexTime = getRandomTime(5000, 10000);
    currIndex = (int)random(0, appleNeonColors.length);
    timer = millis();
  }

  newImg.updatePixels();
  image(newImg, 0, 0);
}

void stop() {
  player.close();
  minim.stop();
  super.stop();
}
