import ddf.minim.*;
import javax.sound.sampled.*;

Minim minim;
AudioInput in;

boolean statsOn = true; // true = backwards line adjusts to be similar to regular line

int bestOffset = 0;
float smallestVariance = Float.MAX_VALUE;

ArrayList<Float> regular = new ArrayList<Float>();
ArrayList<Float> backwards = new ArrayList<Float>();

void setup() {
  size(640, 320, P3D);
  minim = new Minim(this);
  in = minim.getLineIn();
}

void draw() {
  background(20+20*sin(frameCount/10.0));
  
  // add vals to reg and backwards arrays
  for (int i = 0; i < in.bufferSize (); i++) {
    regular.add(in.left.get(i) + in.right.get(i));
    backwards.add(0, in.left.get(i) + in.right.get(i));
  }
  
  int maxSize = width*24;
  if(regular.size() > maxSize) {
    regular = new ArrayList(regular.subList(regular.size() - maxSize, maxSize));
    backwards = new ArrayList(backwards.subList(0, maxSize));
  }
  
  println(backwards.size());
  
  calculateNewOffset();

  // draw waveforms
  int len = regular.size() - 7;
  for (int i = 0; i < len; i+=8) {
    float reg1 = regular.get(i) + regular.get(i+1) + regular.get(i+2) + regular.get(i+3);
    float reg2 = regular.get(i+4) + regular.get(i+5) + regular.get(i+6) + regular.get(i+7);
    float back1 = backwards.get(i) + backwards.get(i+1) + backwards.get(i+2) + backwards.get(i+3);
    float back2 = backwards.get(i+4) + backwards.get(i+5) + backwards.get(i+6) + backwards.get(i+7);
    
    stroke(255);
    line((float)i/len*width, 100+10*reg1, (float)(i+8)/len*width, 100+10*reg2);
    
    stroke(255, 10, 10);
    line((float)(i+bestOffset)/len*width, 200+10*back1, (float)(i+bestOffset+8)/len*width, 200+10*back2);
  }
  
}

void calculateNewOffset() {
  int newOffset = 0;
  float newVariance = Float.MAX_VALUE;
  
  float baseVariance = 0;
  for(int i = 0; i < regular.size(); i++) baseVariance += regular.get(i) * regular.get(i);
  for(int i = 0; i < backwards.size(); i++) baseVariance += backwards.get(i) * backwards.get(i);
  
  for(int offset = -backwards.size(); offset < regular.size(); offset += 100) {
    float thisOffsetVariance = 0;
    
    int start = max(0, offset);
    int end = min(backwards.size() + offset, regular.size());
    
    for(int j = start; j < end; j++) {
      thisOffsetVariance -= regular.get(j) * regular.get(j);
      thisOffsetVariance -= backwards.get(j - offset) * backwards.get(j - offset);
      
      float diff = regular.get(j) - backwards.get(j - offset);
      thisOffsetVariance += diff * diff;
    }
    
    if(baseVariance + thisOffsetVariance < newVariance) {
      newVariance = baseVariance + thisOffsetVariance;
      newOffset = offset;
    }
  }
  
  smallestVariance = newVariance;
  bestOffset = newOffset;
}
