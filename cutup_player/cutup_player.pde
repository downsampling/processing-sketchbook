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

int NUM_BANKS = 2;

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
    
    if (stringList.size()==0) {
      throw new NoSuchElementException("my list is empty");
    }
    if (xPos == -1) {
      return stringList.get(int(random(stringList.size())));
    } else {
      minIndex = int(max(0, xPos-xPad) * stringList.size());
      maxIndex = int(min(1, xPos+xPad) * stringList.size());
      System.out.println("min index: " + minIndex + " max index: " + maxIndex);
      return stringList.get(int(random(minIndex, maxIndex+1)));
    }
  }
  
  void remove() {
    throw new UnsupportedOperationException("cannot remove from this");
  }
  
}

void setup() {
  int i;
  minim = new Minim(this);
  size(800,200);

  for (i=0; i<NUM_BANKS; i++) {
    selectFolder("choose wave folder (bank " + (i+1) + ")", "addFolder");
  }

  sampleChits = new LinkedBlockingQueue<Integer>(16);
  for (i=0; i<16; i++) {
    sampleChits.add(1);
  }
  samples = new LinkedBlockingQueue<AudioSample>(16);
  
  //thread("loadSamples");
}

void loadSamples() {
  String fileName;
  Iterator<String> fileNameIter;
  try {
    fileNameIter = fileNameIters.get(int(random(NUM_BANKS)));
    while (true) {
      if (!fileNameIter.hasNext()) {
        break;
      }
      fileNameIter = fileNameIters.get(int(random(NUM_BANKS)));
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
  if (nextTriggerTime <= millis()) {
    if (currentSample != null) {
      currentSample.close();
      sampleChits.add(1);
    }
    try {
      currentSample = samples.take();
      currentSample.trigger();
      System.out.println("triggering: " + currentSample);
      nextTriggerTime = millis() + currentSample.length() - 5;
    } catch (Exception e) {
      System.out.println("samples.take() failed, error was " + e.toString());
    }
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

