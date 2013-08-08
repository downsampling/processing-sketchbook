import java.util.Iterator;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.Random;
import java.util.NoSuchElementException;
import java.util.Collections;

import ddf.minim.*;

LinkedBlockingQueue<Integer> sampleChits;
LinkedBlockingQueue<AudioSample> samples;
ArrayList<String> fileNames = new ArrayList<String>(); 
Iterator<String> fileNameIter;

float xPos = -1;
float xPad = 0.1;

Minim minim;

void folderSelected(File d) {
  int i;
  String fileName; 

  if (d != null) {
    File[] files = d.listFiles();
    for (i = 0; i < files.length; i++) {
      if (files[i].getName().endsWith(".wav")) {
        fileNames.add(files[i].getAbsolutePath());
      }
    }
    Collections.sort(fileNames);
    fileNameIter = new RandomStringIterator(fileNames);
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

ArrayList<RandomStringIterator> fileNameIterators = new ArrayList<RandomStringIterator>();

void setup() {
  int i;
  minim = new Minim(this);
  size(800,200);

  selectFolder("choose wave folder", "folderSelected");
  /*
  File d = new File(sketchPath(""));
  File[] files = d.listFiles();
  for (i = 0; i < files.length; i++) {
    if (files[i].getName().endsWith(".wav")) {
      fileNames.add(files[i].getName());
    }
  }
    
  fileNameIter = fileNames.iterator();
  */

  sampleChits = new LinkedBlockingQueue<Integer>(16);
  for (i=0; i<16; i++) {
    sampleChits.add(1);
  }
  samples = new LinkedBlockingQueue<AudioSample>(16);
  
  //thread("loadSamples");
}

void loadSamples() {
  String fileName;
  try {
    while (fileNameIter.hasNext()) {
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
  System.out.println("xPos: " + xPos);
}

void mouseReleased() {
  xPos = -1;
  System.out.println("xPos: " + xPos);
}

