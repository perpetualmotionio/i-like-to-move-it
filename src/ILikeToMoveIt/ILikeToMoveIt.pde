import ddf.minim.*;
import ddf.minim.analysis.*;
import SimpleOpenNI.*;
import java.io.*;
import java.util.Arrays;

AudioVisualization audVis;
SimpleOpenNI kinect;
Minim minim;
AudioPlayer player;
FFT fft;

int kinIndex, dispIndex;
int index;
PFont f;
PImage img;
PImage newImg;

// !!!!!!! PLEASE CHANGE !!!!!!!
//final static String sketchDirectory = "/Users/mdavis/code/perpetualmotionio/i-like-to-move-it/src/ILikeToMoveIt/";
final static String sketchDirectory = "/Users/ryankanno/Desktop/PerpetualMotion/Processing/projects/i-like-to-move-it/src/ILikeToMoveIt/";
final boolean shouldScreenCapture = false;


// DO NOT CHANGE
//final String saveDirectory = "/Users/mdavis/Desktop/i-like-to-move-it-images/";
final String saveDirectory = "/Users/ryankanno/Projects/Makerfaire/i-like-to-move-it-images/";
final int milliSecondsBetweenScreenCaptures = 20 * 1000;
boolean isCurrentlyScreenCapturing = false;
String timestamp;
float lengthOfCapture = 0;
int screenCaptureTimer = 0;

color[] appleNeonColors = {
  color(33,121,255),   // neon blue
  color(116,172,0),    // puke green
  color(223,153,0),    // yellow
  color(212,41,66),    // hot pink
  color(149,106,222),  // purnurple
};

int currIndex = 0;
float currIndexTime = 0;
int timer = 0;

static public void main(String args[]) {
   String[] customArgs = new String[] { "--sketch-path=" + sketchDirectory, "--full-screen", "--bgcolor=#000000", "--hide-stop", "ILikeToMoveIt" };
   PApplet.main(concat(args, customArgs));
}

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

  f = createFont("Helvetica", 32, true);
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

  kinect.setMirror(false);
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
  if(userVals == null) return;
  
  int[] imgpix = newImg.pixels;
  
  int idx;
  int val;
  int maxidx = width * height;
  color background = appleNeonColors[currIndex];
  color pix;
  for (idx = 0; idx < maxidx; ++idx){
    val = userVals[idx];
    
    if (val != 0) {
      pix = pixels[idx];
    } else {
      pix = background;
    }
    
    imgpix[idx] = pix;
   
  }

  if (millis() - timer >= currIndexTime) {
    currIndexTime = getRandomTime(5000, 10000);
    currIndex = (currIndex+1) % appleNeonColors.length;
    //currIndex = (int)random(0, appleNeonColors.length);
    timer = millis();
  }

  newImg.updatePixels();
  image(newImg, 0, 0);

  screenCapture();
}

void screenCapture() {
  color bg = appleNeonColors[currIndex];
  int a = (bg>>24)&255;
  int r = (bg>>16)&255;
  int g = (bg>>8)&255;
  int b = (bg>>0)&255;
  
  color textcolor = color(255 - r, 255 - g, 255 - b, 255);
  String msg = "";
  if (!isCurrentlyScreenCapturing) {
    stroke(textcolor);
    int mills_left = millis() - screenCaptureTimer - milliSecondsBetweenScreenCaptures;
  
    if (mills_left > 0) {
      timestamp = year() + nf(month(),2) + nf(day(),2) + "-"  + nf(hour(),2) + nf(minute(),2) + nf(second(),2);
      isCurrentlyScreenCapturing = true;
      lengthOfCapture = getRandomTime(5000, 10000);
      screenCaptureTimer = millis();
    } else if (mills_left >= -1000) {
      msg = "1";  
      noFill();
      stroke(textcolor);
      strokeWeight(20);
      rect(0, 0, width, height);
    } else if (mills_left >= -2000) {
      msg = "2";
    } else if (mills_left >= -3000) {
      msg = "3";
    } else if (mills_left >= -4000) {
      msg = "4";
    } else if (mills_left >= -5000) {
      msg = "5";
    }
    
    if(msg != ""){
      textFont(f,32);
      fill(textcolor);
      text(msg, width - 40, 50);
    }

  } else {
    if (shouldScreenCapture) {
      if (lengthOfCapture > millis() - screenCaptureTimer) {
        if (frameCount % 4 == 0)
        {
            ThreadedImage frame = new ThreadedImage(width, height, RGB, saveDirectory + timestamp + "/frame_" + nf(frameCount, 3) + ".png");
            frame.set(0,0,get());
            frame.save();
        }
      } else {
        PrintWriter output = createWriter(saveDirectory + timestamp + "/DONE");
        output.close();
        isCurrentlyScreenCapturing = false;
        screenCaptureTimer = millis();
      }
    }
  }
}

void stop() {
  player.close();
  minim.stop();
  super.stop();
}
