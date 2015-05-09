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

PImage imgLogo;


final static int MS_LOGO_FLASH_PERIOD = 30 * 1000;
final static int MS_LOGO_FLASH_LENGTH = 5 * 1000;


// !!!!!!! PLEASE CHANGE !!!!!!!
//final static String sketchDirectory = "/Users/mdavis/code/perpetualmotionio/i-like-to-move-it/src/ILikeToMoveIt/";
final static String sketchDirectory = "/Users/ryankanno/Desktop/PerpetualMotion/Processing/projects/i-like-to-move-it/src/ILikeToMoveIt/";
final boolean shouldScreenCapture = true;
final static int screenWidth = 640;
final static int screenHeight = 480;


// DO NOT CHANGE
//final String saveDirectory = "/Users/mdavis/Desktop/i-like-to-move-it/images/";
final String saveDirectory = "/Users/ryankanno/Projects/Makerfaire/i-like-to-move-it-images/";
final int milliSecondsBetweenScreenCaptures = 30 * 1000;
boolean isCurrentlyScreenCapturing = false;
String timestamp;
float lengthOfCapture = 0;
int screenCaptureTimer = 0;

final static int kinectWidth = 640;
final static int kinectHeight = 480;

final static int numDots = 5000;

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


boolean sketchFullScreen()
{
  return true;
}


void setup() {
  println("Sketchdir =",sketchPath(""));
  println("Datadir =",dataPath(""));

  setupKinect();

  size(screenWidth, screenHeight);

  noCursor();

  currIndexTime = getRandomTime(5000, 15000);

  imgLogo = requestImage("logo-white.png", "png");

  audVis = new AudioVisualization();
  newImg = new PImage(kinectWidth, kinectHeight);
  img = new PImage(width, height);
  minim = new Minim(this);

  player = minim.loadFile("song.mp3", 512);
  player.play();
  fft = new FFT(player.bufferSize(), player.sampleRate());

  f = createFont("Helvetica", 32, true);
  background(0);

  for (int i=0; i < numDots; i++) {
    fill(229, 107, 7, random(10, 255));
    ellipse(random(0, width), random(0, height), 4, 4);
  }
  loadPixels();

  for (int y=0; y<height; y++) {
    for (int x=0; x<width; x++) {
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


// centers image to fill screen
// respects aspect ratio of screen and image
void blendImageCenter(PImage blendImg, float scale) {
  int iw = blendImg.width;
  int ih = blendImg.height;
  float wratio = float(width)/iw;
  float hratio = float(height)/ih;
  float ratio = hratio < wratio ? hratio : wratio;

  ratio *= scale;

  int w = int(iw * ratio);
  int h = int(ih * ratio);

  blend(blendImg, 0, 0, iw, ih, width/2 - w/2, height/2 - h/2, w, h, BLEND);
}

void draw() {

  int ms = millis();

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
  int maxidx = kinectWidth * kinectHeight;
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
    timer = millis();
  }

  newImg.updatePixels();
  image(newImg, 0, 0, screenWidth, screenHeight);

  if((ms % MS_LOGO_FLASH_PERIOD) < MS_LOGO_FLASH_LENGTH) {
    blendImageCenter(imgLogo, 0.75);
  }


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
      lengthOfCapture = getRandomTime(7000, 14000);
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
