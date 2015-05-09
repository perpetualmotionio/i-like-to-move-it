import ddf.minim.analysis.*;

class AudioVisualization2 {

  PVector[] pos;
  int[] radius;
  color[] pColor;
  int timer;
  int bufSize;
  float[] bands;
  int cur;
  FFT myFFT;

  color fromHSV(float h, float s, float v, int a){
    float r, g, b;

    int i = int(h * 6);
    int f = int(h * 6 - i);
    float p = v * (1 - s);
    float q = v * (1 - f * s);
    float t = v * (1 - (1 - f) * s);

    switch(i % 6){
    case 0: r = v; g = t; b = p; break;
    case 1: r = q; g = v; b = p; break;
    case 2: r = p; g = v; b = t; break;
    case 3: r = p; g = q; b = v; break;
    case 4: r = t; g = p; b = v; break;
    default:
    case 5: r = v; g = p; b = q; break;
    }

    return color(int(r * 255), int(g * 255), int(b * 255), a);
  }


  AudioVisualization2() {
    myFFT = fft;
    timer = 0;
    bufSize = myFFT.timeSize() / 2; //Nyquist theorem
    pos = new PVector[bufSize];
    radius = new int[bufSize];
    pColor = new color[bufSize];
    bands = new float[bufSize];

    for(int i=0; i < bufSize; i++) {
      pColor[i] = fromHSV(i*360.0/bufSize, 1.0, 0.5+(i*0.5/bufSize), 255);
      pos[i] = new PVector(random(0,width),random(0,height));
    }
    cur = 0;
  }


  void updateFFT(){
    if (null == myFFT){
      return;
    }

    myFFT.forward(player.left);

    for(int i = 0; i < bufSize; ++i){
      bands[i] = myFFT.getBand(i);
    }
  }

  void updatePositions(){
    int nchange = 10;
    for(int i = cur; i < cur+nchange; ++i) {
      pos[i%bufSize].x = random(0, width);
      pos[i%bufSize].y = random(0, height);
    }
    cur = (cur+nchange)%bufSize;
  }

  void renderFFT(){
    noStroke();

    for (int i=0; i < bufSize; i++) {
      float b = bands[i];
      float x = pos[i].x;
      float y = pos[i].y;

      pushMatrix();
      {
        translate(x,y);

        fill(pColor[i], min(255,int(64+b*192)));
        ellipse(0, 0, b*2.5, b*2.5);
      }
      popMatrix();
    }
  }


  void draw(){
    updateFFT();
    updatePositions();
    renderFFT();
  }
}
