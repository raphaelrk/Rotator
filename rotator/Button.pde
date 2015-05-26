class Button {
  
  int x, y, w, h, x2, y2;
  color c;
  String t;
  
  public static final int BTN_REGULAR = 0;
  public static final int BTN_PLAY = 1;
  public static final int BTN_PLAY_BACKWARDS = 2;
  public static final int BTN_RECORD = 3;
  int type = BTN_REGULAR;
  
  public Button(int x, int y, int w, int h, color c, String t) {
    this.x = x;
    this.y = y;
    this.w = w; // width
    this.h = h; // height
    this.c = c; // color
    this.t = t; // text
    
    x2 = x + w;
    y2 = y + h;
  }
  
  public Button(int x, int y, int w, int h, color c, String t, int type) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.c = c;
    this.t = t;
    this.type = type;
    
    x2 = x + w;
    y2 = y + h;
    
    if(this.type == BTN_PLAY_BACKWARDS) {
      this.w = -w;
      this.type = BTN_PLAY;
    }
    
    if(this.type == BTN_PLAY) {
      this.t = "";
      this.c = color(50, 200, 50);
    } else if(this.type == BTN_RECORD) {
      this.t = "";
      this.c = color(200, 50, 50);
    }
  }
  
  public boolean isHoveredOver() {
    if(type == BTN_REGULAR) {
      boolean xInBounds = mouseX >= x && mouseX <= x2;
      boolean yInBounds = mouseY >= y && mouseY <= y2;
      return xInBounds && yInBounds;
    }
    
    else if(type == BTN_PLAY) {
      float p0x  = x,   p0y  = y - h/2.0,
            p1x = x,   p1y = y + h/2.0,
            p2x = x+w, p2y = y;
      float area = 1/2.0*(-p1y*p2x + p0y*(-p1x + p2x) + p0x*(p1y - p2y) + p1x*p2y);
      float s = 1/(2.0*area)*(p0y*p2x - p0x*p2y + (p2y - p0y)*mouseX + (p0x - p2x)*mouseY);
      float t = 1/(2.0*area)*(p0x*p1y - p0y*p1x + (p0y - p1y)*mouseX + (p1x - p0x)*mouseY);
      return (s > 0) && (t > 0) && (1-s-t > 0);
    }
    
    else if(type == BTN_RECORD) {
      return(dist(mouseX, mouseY, x, y+h/2) < max(w/2, h/2));
    }
    
    println("Wut in isHoveredOver");
    return false;
  }
  
  public boolean isPressed() {
    return mousePressed && isHoveredOver();
  }
  
  public void draw() {
    pushStyle();
    stroke(0, 0, 0, 100);
    strokeWeight(1);
    fill(c);
    if(isHoveredOver()) {
      fill(red(c)-10, green(c)-10, blue(c)-10);
      
      if(mousePressed) {
        fill(red(c)-30, green(c)-30, blue(c)-30);
      }
    }
    
    
    if(type == BTN_REGULAR) rect(x, y, w, h);
    if(type == BTN_PLAY) triangle(x, y-h/2, x, y+h/2, x+w, y);
    if(type == BTN_RECORD) ellipse(x, y, w, h);
    
    textAlign(CENTER);
    textSize(24);
    //textSize(1.0 * w / t.length());
    fill(0);
    text(t, x + w/2.0, y + h - (h - textAscent())/2.0);
    popStyle();
  }
  
  public void setColor(color c) {
    this.c = c;
  }
  
  public void setText(String t) {
    this.t = t;
  }
  
}
