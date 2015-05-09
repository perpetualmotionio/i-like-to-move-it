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
PImage imgSilhouetteBackground;
PImage imgLogo;
PImage imgKinectDepth;
PImage imgDepthFrameGeneration;




// !!!!!!! PLEASE CHANGE !!!!!!!
//final static String sketchDirectory = "/Users/ryankanno/Desktop/PerpetualMotion/Processing/projects/i-like-to-move-it/src/ILikeToMoveIt/";
//final String saveDirectory = "/Users/ryankanno/Projects/Makerfaire/i-like-to-move-it-images/";
final static String sketchDirectory = "/Users/mdavis/code/perpetualmotionio/i-like-to-move-it/src/ILikeToMoveIt/";
final String saveDirectory = "/Users/mdavis/Desktop/i-like-to-move-it/images/";


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


// if USER_DEPTH_MAX = 0, the OpenNI user map is used instead
// otherwise the range [0, USER_DEPTH_MAX] will be in silhouette
final static int USER_DEPTH_MAX = 0;

final static int DILATE_ERODE = 0;

final static int TRACER_COUNT = 3;


final static color[][] appleNeonColors = {
  { 33 , 121, 255},  // neon blue
  { 116, 172,   0},  // puke green
  { 223, 153,   0},  // yellow
  { 212,  41,  66},  // hot pink
  { 149, 106, 222},  // purnurple
};

int backgroundColorIndex = 0;
float backgroundSwitchTime = 0;

static public void main(String args[]) {
  String[] customArgs = new String[] { "--sketch-path=" + sketchDirectory, "--full-screen", "--bgcolor=#000000", "--hide-stop", "ILikeToMoveIt" };
  PApplet.main(concat(args, customArgs));
}

boolean sketchFullScreen() {
  return true;
}


PImage createStaticSilhouetteImage() {
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

  imgLogo = requestImage("logo-white.png", "png");

  audVis = new AudioVisualization();
  imgKinectDepth = new PImage(kinectWidth, kinectHeight);
  imgDepthFrameGeneration = new PImage(kinectWidth, kinectHeight);
  minim = new Minim(this);

  player = minim.loadFile("song.mp3", 16*1024);
  player.play();
  fft = new FFT(player.bufferSize(), player.sampleRate());

  f = createFont("Helvetica", 64, true);

  imgSilhouetteBackground = createStaticSilhouetteImage();

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


PImage genNeonOverlayImageFromKinect(int ntracers){
  PImage newImage = new PImage(kinectWidth, kinectHeight);

  newImage.loadPixels();
  imgKinectDepth.loadPixels();
  imgDepthFrameGeneration.loadPixels();
  kinect.update();

  int[] dep_pix = imgKinectDepth.pixels;
  int[] gen_pix = imgDepthFrameGeneration.pixels;
  int[] img_pix = newImage.pixels;
  int[] kin_pix = kinect.userMap();

  if(USER_DEPTH_MAX > 0) {
    kin_pix = kinect.depthMap();
  }

  // Dilate then erode to smooth
  if(DILATE_ERODE > 0){
    PImage tmp = dilate(kin_pix, 640, 480, DILATE_ERODE);
    tmp = erode(tmp, DILATE_ERODE);
    // todo: is this going to access free'd memory?
    kin_pix = tmp.pixels;
  }

  int idx;
  int val;
  int gen;
  float alpha;
  int age;
  int maxidx = kinectWidth * kinectHeight;
  color r = appleNeonColors[backgroundColorIndex][0];
  color g = appleNeonColors[backgroundColorIndex][1];
  color b = appleNeonColors[backgroundColorIndex][2];

  float tracerFactor = 1.0 / ntracers;

  for (idx = 0; idx < maxidx; ++idx){
    val = kin_pix[idx];

    // If the depth value is 0, the kinect cannot resolve it
    // so use the most recent good depth value
    if(val == 0) {
      val = dep_pix[idx];
      gen = gen_pix[idx];
    } else {
      // Otherwise record the good depth value
      dep_pix[idx] = val;
      gen = frameCount;
      gen_pix[idx] = gen;
    }

    // how many frames ago did this depth value get recorded?
    age = frameCount - gen;

    if (age < ntracers && val > 0 && (USER_DEPTH_MAX == 0 || val < USER_DEPTH_MAX)) {
      alpha = age * tracerFactor;
      // saturate the alpha non-linerally
      alpha = sin(age * tracerFactor * 1.57079633); // sin(alpha * pi/2))
    } else {
      alpha = 1.0;
    }

    img_pix[idx] = color(r,g,b,int(min(alpha, 1.0)*255.5));
  }

  newImage.updatePixels();
  return newImage;
}


void checkAndUpdateBackgroundColor() {
  if (millis() > backgroundSwitchTime) {
    backgroundSwitchTime = millis() + getRandomTime(5000, 10000);
    backgroundColorIndex = (backgroundColorIndex+1) % appleNeonColors.length;
  }
}



void draw() {
  background(imgSilhouetteBackground);
  audVis.draw();

  checkAndUpdateBackgroundColor();

  PImage overlayImg = genNeonOverlayImageFromKinect(TRACER_COUNT);
  blendImageCenter(overlayImg, 1.0);


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
  int r = appleNeonColors[backgroundColorIndex][0];
  int g = appleNeonColors[backgroundColorIndex][1];
  int b = appleNeonColors[backgroundColorIndex][2];
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

  int x = 50;
  int y = 50;
  if(msg != ""){
    textFont(f,32);

    stroke(0);
    fill(0);
    text(msg, x-1, y-1);
    text(msg, x-1, y+1);
    text(msg, x+1, y-1);
    text(msg, x+1, y+1);

    stroke(textcolor);
    fill(textcolor);

    text(msg, x, y);
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
