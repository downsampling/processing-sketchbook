import java.util.Iterator;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.Random;
import java.util.NoSuchElementException;

import ddf.minim.*;

LinkedBlockingQueue<Integer> sampleChits;
LinkedBlockingQueue<AudioSample> samples;
ArrayList<String> fileNames = new ArrayList<String>(); 
Iterator<String> fileNameIter;

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
    if (stringList.size()==0) {
      throw new NoSuchElementException("my list is empty");
    }      
    return stringList.get(randomGenerator.nextInt(stringList.size()));
  }
  
  void remove() {
    throw new UnsupportedOperationException("cannot remove from this");
  }
  
}

void setup() {
  int i;
  minim = new Minim(this);

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
  int x;
  String fileName;
  try {
    while (fileNameIter.hasNext()) {
      x = sampleChits.take();
      fileName = fileNameIter.next();
      System.out.println("loading sample " + x + " for file " + fileName);
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

