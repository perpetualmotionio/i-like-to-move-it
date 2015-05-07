class AudioVisualization {

  PVector[] pos;
  int[] radius;
  color[] pColor;
  int timer;

  AudioVisualization() {
    timer = 50;
    pos = new PVector[200];
    radius = new int[200];
    pColor = new color[200];

    for(int i=0; i < 200; i++) {
      pos[i] = new PVector(random(0,width), random(0,height));
      if(i <10) {
        pColor[i]= color(146,255,255);
        radius[i]= 10;
      }
      else if(i < 28) {
        pColor[i]= color(35,250,46);
        radius[i]= 8;
      }
      else if(i < 55) {
        pColor[i]= color(255,255,45);
        radius[i]= 6;
      }
      else if(i < 85) {
        pColor[i]= color(255,84,145);
        radius[i] = 5;
      }
      else if(i < 122) {
        pColor[i]= color(255);
        radius[i]= 4;
      }
      else if(i < 150) {
        pColor[i]= color(215,82,213);
        radius[i]= 3;
      }
      else {
        pColor[i]= color(255,30,5);
        radius[i]= 2;
      }
    }
  }

  void draw(){
    noStroke();
    fft.forward(player.left);
    for (int i=1; i < 200; i++) {
      if (timer < 0) {
        pos[i].x = random(0,width);
        pos[i].y = random(0,height);
      }
      pushMatrix();

      translate(pos[i].x,pos[i].y);

      for(int n=0; n<70; n++) {
        fill(pColor[i], fft.getBand(i) * 2.5);
        ellipse(random(-fft.getBand(i) * 2, fft.getBand(i)*2), random(-fft.getBand(i)*2,fft.getBand(i)*2), radius[i], radius[i] ); 
      }
      popMatrix();
    }

    if(timer < 0)
    {
      timer=50;
    }
    timer--;
  }
}
