/**
 * This sketch demonstrates how to an <code>AudioRecorder</code> to record audio to disk. 
 * To use this sketch you need to have something plugged into the line-in on your computer, 
 * or else be working on a laptop with an active built-in microphone. 
 * <p>
 * Press 'r' to toggle recording on and off and the press 's' to save to disk. 
 * The recorded file will be placed in the sketch folder of the sketch.
 * <p>
 * For more information about Minim and additional features, 
 * visit http://code.compartmental.net/minim/
 */

import ddf.minim.*;
import javax.sound.sampled.*;

Minim minim;
AudioInput in;
AudioRecorder recorder;
AudioPlayer player;

int welcomeScreen = 0;
int currScreen = welcomeScreen;

boolean firstRecorded = false;
boolean secondRecorded = false;
float[] regular, backwards;

Button recordBtnOne, playBtnOne, recordBtnTwo, playBtnTwo;
Button backwardsBtn;

AudioSample recordingOne, recordingTwo;

int titleTextY = 64;
int upperRecordLineY = 200;
int lowerRecordLineY = 300;

int bestOffset = 0;
float smallestVariance = Float.MAX_VALUE;

void setup() {
  size(400, 640, P3D);

  minim = new Minim(this);

  in = minim.getLineIn();
  // create a recorder that will record from the input to the filename specified
  // the file will be located in the sketch's root folder.
  recorder = minim.createRecorder(in, "firstrecording.wav");

  recordBtnOne = new Button(width-40, upperRecordLineY - 40, 15, 15, color(200, 50, 50), "RECORD", Button.BTN_RECORD);
  playBtnOne = new Button(width-20, upperRecordLineY - 40, 15, 15, color(100, 150, 100), "PLAY", Button.BTN_PLAY);
  recordBtnTwo = new Button(width-40, lowerRecordLineY - 40, 15, 15, color(200, 50, 50), "RECORD", Button.BTN_RECORD);
  playBtnTwo = new Button(width-20, lowerRecordLineY - 40, 15, 15, color(100, 150, 100), "PLAY", Button.BTN_PLAY);
  backwardsBtn = new Button(width/2-75, 360, 150, 40, color(100, 100, 240), "PLAY BACK");

  textFont(createFont("Tahoma", 64));
}

void draw() {
  background(20+20*sin(frameCount/10.0));

  // debug for placing new things
  // println("X: " + mouseX + " Y: " + mouseY);

  // draw title
  fill(255);
  textAlign(CENTER);
  textSize(64);
  text("ROTATO  ", width/2, titleTextY);

  // draw the backwards R in "ROTATOR"
  pushMatrix();
  translate(width/2 + 120, titleTextY);
  scale(-1, 1);
  text("R", 0, 0);
  popMatrix();

  // draw the waveform of the microphone
  // the values returned by left.get() and right.get() will be between -1 and 1,
  // so the combined value is halved to maintain normality
  for (int i = 0; i < in.bufferSize () - 1; i++) {
    float lrCombinedOne = (in.left.get(i)   + in.right.get(i)  )/2.0;
    float lrCombinedTwo = (in.left.get(i+1) + in.right.get(i+1))/2.0;
    stroke(255, 10, 10);
    line(i, upperRecordLineY + lrCombinedOne*50, i+1, upperRecordLineY + lrCombinedTwo*50); // upper line
    stroke(255);
    line(i, lowerRecordLineY + lrCombinedOne*50, i+1, lowerRecordLineY + lrCombinedTwo*50); // lower line
  }

  // directions/status
  textAlign(LEFT);
  textSize(14);
  if (firstRecorded) {
    text("Regular recording registered", 10, upperRecordLineY - 50);
  } else {
    text("Regular recording ready to be made", 10, upperRecordLineY - 50);
  }

  if (secondRecorded) {
    text("Backwards recording registered", 10, lowerRecordLineY - 50);
  } else {
    text("Backwards recording ready to be made", 10, lowerRecordLineY - 50);
  }

  textAlign(CENTER);
  textSize(24);
  if (firstRecorded && secondRecorded)
    text("Both recorded!", width/2, 100);


  // draw record and play buttons
  recordBtnOne.draw();
  playBtnOne.draw();
  recordBtnTwo.draw();
  playBtnTwo.draw();
  if (firstRecorded && secondRecorded) backwardsBtn.draw();

  // keep play buttons greyed out or normal green when not playing
  if (player == null || !player.isPlaying()) {
    if (firstRecorded)
      playBtnOne.setColor(color(50, 200, 50));
    else
      playBtnOne.setColor(color(100, 150, 100));

    if (secondRecorded)
      playBtnTwo.setColor(color(50, 200, 50));
    else
      playBtnTwo.setColor(color(100, 150, 100));
  }
  
  // draw form of first recordings
  if (firstRecorded) {
    int len = regular.length - 7;
    for (int i = 0; i < len; i+=8) {
      float reg1 = regular[i] + regular[i+1] + regular[i+2] + regular[i+3];
      float reg2 = regular[i+4] + regular[i+5] + regular[i+6] + regular[i+7];
      
      stroke(255, 10, 10, 100 + 80*cos(frameCount/11.0));
      line((float)i/len*width, 500+10*reg1, (float)(i+8)/len*width, 500+10*reg2);
    }
  }
  
  // draw form of second recording
  if(secondRecorded) {
    int len = backwards.length - 7;
    for (int i = 0; i < len; i+=4) {
      float back1 = backwards[i] + backwards[i+1] + backwards[i+2] + backwards[i+3];
      float back2 = backwards[i+4] + backwards[i+5] + backwards[i+6] + backwards[i+7];
      
      stroke(255, 255, 255, 100 + 80*sin(frameCount/17.0));
      line((float)(i+bestOffset)/len*width, 500+10*back1, (float)(i+bestOffset+8)/len*width, 500+10*back2);
      
      // draw w/o bestoffset
      //stroke(10, 255, 10, 100 + 80*sin(-frameCount/11.0));
      //line((float)(i)/len*width, 500+10*back1, (float)(i+8)/len*width, 500+10*back2);
    }
  }
}

void playRevert() {
  float[] forwardLeft = recordingOne.getChannel(AudioSample.LEFT);
  float[] forwardRight = recordingOne.getChannel(AudioSample.RIGHT);
  float[] backwardLeft = reverseArr(recordingTwo.getChannel(AudioSample.LEFT));
  float[] backwardRight = reverseArr(recordingTwo.getChannel(AudioSample.RIGHT));
  
  int offset = bestOffset;
  int len = max(regular.length, backwards.length + offset) - min(0, offset);
  float[] forwardRecLeft = new float[len], forwardRecRight = new float[len],
          backwardRecLeft= new float[len], backwardRecRight= new float[len];
  
  for(int i = 0; i < len; i++) {
    if(offset < 0) {
      if(i >= offset && i - offset < forwardLeft.length) {
        forwardRecLeft[i] = forwardLeft[i - offset];
        forwardRecRight[i]= forwardRight[i- offset];
      } 
      if(i < backwardLeft.length) {
        backwardRecLeft[i] = backwardLeft[i];
        backwardRecRight[i]= backwardRight[i];
      }
    } else {
      if(i >= offset && i - offset < backwardLeft.length) {
        backwardRecLeft[i] = backwardLeft[i - offset];
        forwardRecRight[i] = backwardRight[i- offset];
      }
      
      if(i < forwardLeft.length) {
        forwardRecLeft[i] = forwardLeft[i];
        forwardRecRight[i] = forwardRight[i];
      }
    }
  }
  
  
  /*
  int start = max(0, bestOffset);
  int end = min(backwards.length + bestOffset, regular.length);
  
  float[] recordingTwoLeftOffset = new float[end];
  float[] recordingTwoRightOffset = new float[end];
  
  for(int i = 0; i < end; i++) {
    if(i < start) {
      recordingTwoLeftOffset[i] = 0;
      recordingTwoRightOffset[i] = 0;
    } else {
      recordingTwoLeftOffset[i] = recordingTwoLeft[i-start];
      recordingTwoRightOffset[i] = recordingTwoRight[i-start];
    }
  }*/
  
  AudioSample backwards = minim.createSample(backwardRecLeft, 
                                             backwardRecRight, 
                                             recordingTwo.getFormat());

  AudioSample forwards = minim.createSample(forwardRecLeft, 
                                            forwardRecRight, 
                                            recordingOne.getFormat());

  backwards.trigger();
  forwards.trigger();
}

// used to sum left and right audio channels into one array
float[] sumArrays(float[] arr1, float[] arr2) {
  if (arr1.length != arr2.length) println("sumArrays: lengths don't matched");

  float[] newArr = new float[arr1.length];
  for (int i = 0; i < arr1.length; i++) {
    newArr[i] = arr1[i] + arr2[i];
  }

  return newArr;
}

// used to flip recording array to make backwards one
float[] reverseArr(float[] arr) {
  float[] newArr = new float[arr.length];
  for (int i = 0; i < arr.length; i++) {
    newArr[i] = arr[arr.length-1-i];
  }

  return newArr;
}

// prints offset and a score derived from variance
void printOffsetAndVariance() {
  println("offset: " + bestOffset);
  println("score: " + (smallestVariance/(regular.length + backwards.length)*10000) + "\n");
}

// calculates best offset of backwards recording to match regular one
void calculateNewOffset() {
  int newOffset = 0;
  float newVariance = Float.MAX_VALUE;
  
  float baseVariance = 0;
  for(int i = 0; i < regular.length; i++) baseVariance += regular[i] * regular[i];
  for(int i = 0; i < backwards.length; i++) baseVariance += backwards[i] * backwards[i];
  
  for(int offset = -backwards.length; offset < regular.length; offset += 100) {
    float thisOffsetVariance = calculateThisOffsetVariance(offset);
    
    if(abs(baseVariance + thisOffsetVariance) < abs(newVariance)) {
      newVariance = baseVariance + thisOffsetVariance;
      newOffset = offset;
    }
  }
  
  smallestVariance = newVariance;
  bestOffset = newOffset;
  printOffsetAndVariance();
}

// used in calculateNewOffset() to calculate variance of individual offset
float calculateThisOffsetVariance(int offset) {
  float thisOffsetVariance = 0;
    
  int start = max(0, offset);
  int end = min(backwards.length + offset, regular.length);
  
  for(int j = start; j < end; j++) {
    thisOffsetVariance -= regular[j] * regular[j];
    thisOffsetVariance -= backwards[j - offset] * backwards[j - offset];
    
    float diff = abs(regular[j]) - abs(backwards[j - offset]);
    thisOffsetVariance += diff * diff;
  }
  
  return thisOffsetVariance;
}

void mouseReleased() {
  
  // record button pressed
  Button[] recordBtns = { recordBtnOne, recordBtnTwo };
  for (int i = 0; i < recordBtns.length; i++) {
    Button recordBtn = recordBtns[i];
    if (recordBtn.isHoveredOver()) {
      if (recorder.isRecording()) {
        recorder.endRecord();
        recordBtn.setColor(color(200, 50, 50));
        recorder.save();

        if (i == 0) {
          recordingOne = minim.loadSample("firstrecording.wav");
          regular = sumArrays(recordingOne.getChannel(AudioSample.LEFT), recordingOne.getChannel(AudioSample.RIGHT));
          firstRecorded = true;
        } else if (i == 1) {
          recordingTwo = minim.loadSample("secondrecording.wav");
          backwards = reverseArr(sumArrays(recordingTwo.getChannel(AudioSample.LEFT), recordingTwo.getChannel(AudioSample.RIGHT)));
          secondRecorded = true;
        }

        if (firstRecorded && secondRecorded) calculateNewOffset();

        println("saved");
      } else {
        if (i == 0) recorder = minim.createRecorder(in, "firstrecording.wav");
        if (i == 1) recorder = minim.createRecorder(in, "secondrecording.wav");

        recorder.beginRecord();
        recordBtn.setColor(color(255, 150, 150));
      }
    }
  }
  
  // play button pressed
  Button[] playBtns = { playBtnOne, playBtnTwo };
  boolean[] recorded = { firstRecorded, secondRecorded };
  for (int i = 0; i < playBtns.length; i++) {
    Button playBtn = playBtns[i];
    if (playBtn.isHoveredOver() && recorded[i] == true) {
      if (player != null && player.isPlaying()) {
        player.pause();
        player.rewind();
      } else {
        if (i == 0) player = minim.loadFile("firstrecording.wav");
        if (i == 1) player = minim.loadFile("secondrecording.wav");

        //player.seek
        player.play();
        playBtn.setColor(color(150, 255, 150));
      }
    }
  }
  
  // backwards playback button pressed
  if (backwardsBtn.isHoveredOver()) {
    playRevert();
  }
}

void keyPressed() {
  if(keyCode == LEFT || keyCode == RIGHT) {
    if(keyCode == LEFT) bestOffset -= 100;
    if(keyCode == RIGHT) bestOffset += 100;
    
    float baseVariance = 0;
    for(int i = 0; i < regular.length; i++) baseVariance += regular[i] * regular[i];
    for(int i = 0; i < backwards.length; i++) baseVariance += backwards[i] * backwards[i];
    
    float thisOffsetVariance = calculateThisOffsetVariance(bestOffset);
      
    smallestVariance = baseVariance + thisOffsetVariance;
    printOffsetAndVariance();
  }
}
