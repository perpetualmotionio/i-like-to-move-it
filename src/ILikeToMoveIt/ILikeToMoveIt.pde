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




// !!!!!!! PLEASE CHANGE !!!!!!!
final static String sketchDirectory = "/Users/ryankanno/Desktop/PerpetualMotion/Processing/projects/i-like-to-move-it/src/ILikeToMoveIt/";
final String saveDirectory = "/Users/ryankanno/Projects/Makerfaire/i-like-to-move-it-images/";
//final static String sketchDirectory = "/Users/mdavis/code/perpetualmotionio/i-like-to-move-it/src/ILikeToMoveIt/";
//final String saveDirectory = "/Users/mdavis/Desktop/i-like-to-move-it/images/";


final static int screenWidth = 640*3/2;
final static int screenHeight = 480*3/2;
final static int kinectWidth = 640;
final static int kinectHeight = 480;

final static int numDots = 5000;


// 0 = normal display
// 1 = display tweet countdown
// 2 = capture tweet
// 3 = display logo
int captureMode = 0;
int captureModeEndTime = 0;
String captureDirectory;

final static int MS_IDLE_MIN = 10 * 1000;
final static int MS_IDLE_MAX = 30 * 1000;
final static int MS_LOGO_FLASH_LENGTH = 10 * 1000;
final static int MS_COUNTDOWN = 5 * 1000;
final static int MS_CAPTURE_MIN = 7 * 1000;
final static int MS_CAPTURE_MAX = 14 * 1000;


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

boolean sketchFullScreen() {
  return true;
}


PImage createShilouetteImage() {
  background(0);

  for (int i=0; i < numDots; i++) {
    fill(229, 107, 7, random(10, 255));
    ellipse(random(0, width), random(0, height), 4, 4);
  }
  loadPixels();

  return get();
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

  f = createFont("Helvetica", 64, true);

  img = createShilouetteImage();

  captureMode = -1;
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


int getRandomTime(int minTime, int maxTime) {
  return int(random(minTime, maxTime));
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



int getCurrentCaptureMode(){
  int ms = millis();

  // return early if timer for next mode is not elapsed
  if(ms < captureModeEndTime){
    return captureMode;
  }

  int modeLength;
  ++captureMode;

  if(captureMode == 1){
    modeLength = MS_COUNTDOWN;
  } else if(captureMode == 2){
    startScreenCapture();
    modeLength = getRandomTime(MS_CAPTURE_MIN, MS_CAPTURE_MAX);
  } else if(captureMode == 3) {
    finishScreenCapture();
    modeLength =  MS_LOGO_FLASH_LENGTH;
  } else {
    captureMode = 0;
    modeLength = getRandomTime(MS_IDLE_MIN, MS_IDLE_MAX);
  }

  captureModeEndTime = ms + modeLength;
  return captureMode;
}



void draw() {
  background(img);
  audVis.draw();
  kinect.update();

  loadPixels();

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


  switch(getCurrentCaptureMode()){
  case 1: displayCountdown(); break;
  case 2: doScreenCapture(); break;
  case 3: blendImageCenter(imgLogo, 0.75); break;
  default: break;
  }
}


// called when mode switches to capture
void startScreenCapture() {
  captureDirectory = saveDirectory + year() + nf(month(),2) + nf(day(),2) + "-"  + nf(hour(),2) + nf(minute(),2) + nf(second(),2);
}


// called when mode switches to logo
void finishScreenCapture() {
  PrintWriter output = createWriter(captureDirectory + "/DONE");
  output.close();
}


// called in draw() when mode is capture
void doScreenCapture() {
  if (frameCount % 4 == 0)
  {
    ThreadedImage frame = new ThreadedImage(width, height, RGB, captureDirectory + "/frame_" + nf(frameCount, 3) + ".png");
    frame.set(0,0,get());
    frame.save();
  } else {
    displayMsgAndFrame(getTextcolor(), "RECORDING", 30);
  }
}


color getTextcolor() {
  color bg = appleNeonColors[currIndex];
  int a = (bg>>24)&255;
  int r = (bg>>16)&255;
  int g = (bg>>8)&255;
  int b = (bg>>0)&255;
  color textcolor = color(255 - r, 255 - g, 255 - b, 255);
  return textcolor;
}


void displayMsgAndFrame(color textcolor, String msg, int frameWidth){
  if(frameWidth > 0) {
    noFill();
    stroke(textcolor);
    strokeWeight(frameWidth);
    rect(0, 0, width, height);
  }

  if(msg != ""){
    textFont(f,32);
    stroke(textcolor);
    fill(textcolor);
    text(msg, 50, 50);
  }
}


void displayCountdown(){
  float seconds = (captureModeEndTime - millis()) * 0.001;
  String msg = "Get ready to tweet in " + nf(int(seconds)+1,1) + " seconds!";
  int frameWid = int(seconds) * 10;
  displayMsgAndFrame(getTextcolor(), msg, frameWid);
}


void stop() {
  player.close();
  minim.stop();
  super.stop();
}
