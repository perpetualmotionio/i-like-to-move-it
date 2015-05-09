
PImage dilate(PImage srcimg, int n){
  srcimg.loadPixels();
  return dilate(srcimg.pixels, srcimg.width, srcimg.height, n);
}


PImage dilate(int[] src, int wid, int hei, int n){
  int x;
  int y;
  int ix;
  int iy;
  int x0;
  int y0;
  int x1;
  int y1;
  int sidx;
  int didx;
  PImage dstimg = new PImage(wid,hei);
  dstimg.loadPixels();
  int[] dst = dstimg.pixels;
  int val;

  for(y = 0; y < hei; ++y){
    y0 = max(0, y-n);
    y1 = min(y+n, hei);
    for(x = 0; x < wid; ++x){
      didx = y*wid+x;
      x0 = max(0, x-n);
      x1 = min(x+n, wid);
      val = src[didx];
      for(iy = y0; iy < y1; ++iy){
        for(ix = x0; ix < x1; ++ix){
          sidx = iy*wid+ix;
          val = max(val, src[sidx]);
        }
      }
      dst[didx] = val;
    }
  }
  dstimg.updatePixels();
  return dstimg;
}


PImage erode(PImage srcimg, int n){
  srcimg.loadPixels();
  return erode(srcimg.pixels, srcimg.width, srcimg.height, n);
}


PImage erode(int[] src, int wid, int hei, int n){
  int x;
  int y;
  int ix;
  int iy;
  int x0;
  int y0;
  int x1;
  int y1;
  int sidx;
  int didx;
  PImage dstimg = new PImage(wid,hei);
  dstimg.loadPixels();
  int[] dst = dstimg.pixels;
  int val;
  for(y = 0; y < hei; ++y){
    y0 = max(0, y-n);
    y1 = min(y+n, hei);
    for(x = 0; x < wid; ++x){
      didx = y*wid+x;
      x0 = max(0, x-n);
      x1 = min(x+n, wid);
      val = src[didx];
      for(iy = y0; iy < y1; ++iy){
        for(ix = x0; ix < x1; ++ix){
          sidx = iy*wid+ix;
          val = min(val, src[sidx]);
        }
      }
      dst[didx] = val;
    }
  }
  dstimg.updatePixels();
  return dstimg;
}

