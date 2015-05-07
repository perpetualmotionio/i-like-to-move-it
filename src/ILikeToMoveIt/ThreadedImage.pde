// https://stackoverflow.com/questions/22124039/exporting-a-gif-from-a-processing-sketch-w-gif-animation-library
class ThreadedImage extends PImage implements Runnable {

  String absoluteFilePath;

  ThreadedImage(int w, int h, int format, String absoluteFilePath) {
    this.absoluteFilePath = absoluteFilePath;
    init(w, h, format);
  }

  public void save() {
    new Thread(this).start();
  }

  public void run(){
    this.save(this.absoluteFilePath);
  }
}
