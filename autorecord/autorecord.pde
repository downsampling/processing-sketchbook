import ddf.minim.*;

Minim minim;
AudioInput input;
AudioRecorder recorder;
AudioPlayer player;

int playCnt;
int recCnt;

ArrayList getWaveFiles() {
  ArrayList<File> fileList = new ArrayList<File>();
  File file = new File(sketchPath(""));
  File[] files = file.listFiles();
  for (int i = 0; i < files.length; i++) {
    if (files[i].getName().endsWith(".wav")) {
      fileList.add(files[i]);
    }
  }
  return(fileList);
}

void playRandomWaveFiles() throws Exception {
  while (true) {
    ArrayList<File> waveFiles = getWaveFiles();
    File waveFile = waveFiles.get(int(random(waveFiles.size())));
    System.out.println("play: " + waveFile.getName());
    try {
        player = minim.loadFile(waveFile.getName());
        player.play();
    } catch (Exception e) {
      System.out.println("exception trying to play file: " + e.toString());
      throw e;
    }
    while (true) {
      if (player.isPlaying()) {
        try {
          Thread.sleep(1000);
        } catch (Exception e) {
          Thread.currentThread().interrupt();
        }
      } else {
	player.close();
        break;
      }
    }
  }
}

AudioInput getInput() {
  return input;
}

AudioRecorder getRecorder(String filename) {
  System.out.println("recorder: " + filename);
  return minim.createRecorder(getInput(), filename, true);
}

boolean isRecording() {
  return (recorder != null && recorder.isRecording()); 
}

void startRecording() {
  if (!isRecording()) {
    if (recorder == null) {
      recorder = getRecorder(int(random(100))+".wav");
    }
    try {
      recorder.beginRecord();
    } catch (Exception e) {
      System.out.println("caught on beginRecord:" + e.toString());
    }
  }
}

void finishRecording() {
  if (isRecording()) {
    recorder.endRecord();
    recorder.save();
    recorder = null;
  }
}

void setup()
{
  size(512, 200, P3D);
  
  minim = new Minim(this);
  //minim.debugOn();
  input = minim.getLineIn();
  textFont(createFont("Arial", 12));
  
  thread("playRandomWaveFiles");
}

float threshold = 400;
int delay = 1000; // msec before stop recording
int timeout;

void draw()
{
  if (false && input.mix.level() * 1000 > threshold) {
    startRecording();
    timeout = millis() + delay;
  } else {
    if (millis() > timeout) {
      finishRecording();
    }
  }
  background(0);
  stroke(255);
  if ( isRecording() )
  {
    text("Currently recording...", 5, 15);
  }
  else
  {
    text("Not recording.", 5, 15);
  }
  text("player: " + player, 5, 45);
  text("recorder: " + recorder, 5, 60);
  text("input: " + input, 5, 75);
  text("player.isPlaying()" + player.isPlaying(), 5, 90);
}


