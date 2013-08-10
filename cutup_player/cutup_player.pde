import codeanticode.gsvideo.*;
import monclubelec.javacvPro.*;

PImage img;

Blob[] blobsArray=null;
GSCapture cam;
OpenCV opencv;

import java.util.Iterator;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.Random;
import java.util.NoSuchElementException;
import java.util.Collections;

import ddf.minim.*;

LinkedBlockingQueue<Integer> sampleChits;
LinkedBlockingQueue<AudioSample> samples;

ArrayList<Iterator<String>> fileNameIters = new ArrayList<Iterator<String>>();

float xPos = -1;
float xPad = 0.1;
float yPos = -1;
float yPad = 0.1;

int NUM_BANKS = 5;
int CHEAT_FACTOR = 10;

boolean cvDisabled = false;
boolean audioPaused = false;

Minim minim;

void addFolder(File d) {
  int i;
  String fileName; 
  ArrayList<String> fileNames = new ArrayList<String>(); 
  Iterator<String> fileNameIter;
  
  if (d != null) {
    File[] files = d.listFiles();
    for (i = 0; i < files.length; i++) {
      if (files[i].getName().endsWith(".wav")) {
        fileNames.add(files[i].getAbsolutePath());
      }
    }
    Collections.sort(fileNames);
    fileNameIter = new RandomStringIterator(fileNames);
    System.out.println("adding " + d.getName());
    newFileNameIter(fileNameIter);
  }
}

void newFileNameIter(Iterator<String> i) {
    fileNameIters.add(i);
    if (fileNameIters.size() == NUM_BANKS) {
      thread("loadSamples");
    }
}

class RandomStringIterator implements Iterator {
  
  ArrayList<String> stringList;
  Random randomGenerator;
  
  RandomStringIterator(ArrayList<String> stringList) {
    this.randomGenerator = new Random();
    setList(stringList);
  }
  
  void setList(ArrayList<String> stringList) {
    this.stringList = stringList;
  }
  
  boolean hasNext() {
    return stringList.size() > 0;
  }
  
  String next() {

    int minIndex;
    int maxIndex;
    float xPosLocal = xPos;
    float xPadLocal = xPad;
    
    if (stringList.size()==0) {
      throw new NoSuchElementException("my list is empty");
    }
    if (xPos == -1) {
      return stringList.get(int(random(stringList.size())));
    } else {
      minIndex = int(max(0, xPosLocal-xPadLocal) * stringList.size());
      maxIndex = int(min(1, xPosLocal+xPadLocal) * stringList.size());
      System.out.println("min index: " + minIndex + " max index: " + maxIndex);
      return stringList.get(int(random(minIndex, maxIndex)));
    }
  }
  
  void remove() {
    throw new UnsupportedOperationException("cannot remove from this");
  }
  
}

void setup() {

  size(1184, 656);
  //frameRate(10);
  cam = new GSCapture(this, width, height);
  opencv = new OpenCV(this); // initialise objet OpenCV à partir du parent This
  opencv.allocate(width, height); // initialise les buffers OpenCv à la taille de l'image
  cam.start();  // démarre objet GSCapture = la webcam 

  int i;
  minim = new Minim(this);

  for (i=0; i<NUM_BANKS; i++) {
    selectFolder("choose wave folder (bank " + (i+1) + ")", "addFolder");
  }

  sampleChits = new LinkedBlockingQueue<Integer>(16);
  for (i=0; i<16; i++) {
    sampleChits.add(1);
  }
  samples = new LinkedBlockingQueue<AudioSample>(16);
  
}

void loadSamples() {
  String fileName;
  Iterator<String> fileNameIter;
  int minIndex;
  int maxIndex;
  try {
    fileNameIter = fileNameIters.get(int(random(NUM_BANKS)));
    while (true) {
      if (!fileNameIter.hasNext()) {
        break; // TODO shouldn't break unless all iters are exhausted?
      }
      // choose a bank based on y pos
      if (yPos == -1) {
        fileNameIter = fileNameIters.get(int(random(NUM_BANKS)));
      } else {
        minIndex = int(max(0, yPos-yPad) * NUM_BANKS);
        maxIndex = int(min(1, yPos+yPad) * NUM_BANKS);
        System.out.println("bank range: (" + minIndex + "," + maxIndex + ")");
        fileNameIter = fileNameIters.get(int(random(minIndex, maxIndex)));
      }
      
      sampleChits.take();
      fileName = fileNameIter.next();
      System.out.println("loading sample for file " + fileName);
      samples.put(minim.loadSample(fileName));
    }
    System.out.println("no more filenames to iterate.");
  } catch (Exception e) {
    System.out.println("loadSamples quit, error was " + e.toString());
  }
}

int nextTriggerTime = millis();
AudioSample currentSample;

void draw() {
  
  background(255);
  
  if (audioPaused) {
    fill(0);
    textSize(10);
    text("audio is paused", 10, height - 10);
  } else if (nextTriggerTime <= millis()) {
    if (currentSample != null) {
      currentSample.close();
      sampleChits.add(1);
    }
    try {
      currentSample = samples.take();
      currentSample.trigger();
      System.out.println("triggering: " + currentSample);
      nextTriggerTime = millis() + currentSample.length() - (cvDisabled ? CHEAT_FACTOR : CHEAT_FACTOR * 2);
    } catch (Exception e) {
      System.out.println("samples.take() failed, error was " + e.toString());
    }
  }
  
  if (cvDisabled) {
    fill(0);
    textSize(10);
    text("cv is disabled", width - 90, height - 10);
    xPos = -1;
    yPos = -1;
  } else if (cam.available() == true) { // si une nouvelle frame est disponible sur la webcam
    cam.read(); // acquisition d'un frame 
    opencv.copy(cam.get()); // autre possibilité - charge directement l'image GSVideo dans le buffer openCV
    opencv.flip("HORIZONTAL");
    opencv.threshold(0.5, "BINARY"); // seuillage binaire pour éliminer le fond 
    blobsArray = opencv.blobs(opencv.area()/64, opencv.area()/2, 1, false, 1000, false ); // blobs javacvPro +/- debug    
    if (blobsArray.length > 0) {
      xPad = (blobsArray[0].rectangle.width/2) / float(width);
      yPad = (blobsArray[0].rectangle.height/2) / float(height);
      xPos = (blobsArray[0].centroid.x) / float(width);
      yPos = (blobsArray[0].centroid.y) / float(height);
      System.out.println("xPos:" + xPos + " xPad:" + xPad + " yPos:" + yPos + " yPad:" + yPad);
      //stroke(0);
      //rect(x-xp, y-yp, xp*2, yp*2);
    }
  } else {
    xPos = -1;
    yPos = -1;
  }

  if (xPos >= 0 && yPos >= 0) {
    //fill(255);
    //ellipse(mouseX, mouseY, width * xPad * 2, height * yPad * 2);
    stroke(0);
    noFill();
    rect((xPos-xPad)*width, (yPos-yPad)*height, xPad*2*width, yPad*2*height);
  }
  
}

void mouseDragged() {
  xPos = mouseX / float(width);
  yPos = mouseY / float(height);
  System.out.println("xPos: " + xPos);
}

void mouseReleased() {
  xPos = yPos = -1;
  System.out.println("xPos / yPos reset");
}

void keyReleased() {
  if (key == ' ') {
    audioPaused = !audioPaused;
    System.out.println("audioPaused is " + audioPaused);
  } else if (key == 'c') {
    cvDisabled = !cvDisabled;
    System.out.println("cvDisabled is " + cvDisabled);
  }
}

