public class Button {
  String text;
  float x, y, width, height;
  boolean isHovering;

  Button(String _text, float _x, float _y, float _width, float _height) {
    text = _text;
    x = _x;
    y = _y;
    width = _width;
    height = _height;
    
    isHovering = false;

    Interactive.add(this);
  }

  void mousePressed() {
    Interactive.send(this, "click", this);
  }

  void mouseEntered() {
    isHovering = true;
  }
 
  void mouseExited() {
    isHovering = false;
  }

  void draw() {
    fill(isHovering ? 175 : 200);
    stroke(20);
    strokeWeight(1);
    rect(x, y, width, height);
    
    fill(0);
    textAlign(CENTER, CENTER);
    text(text, x, y, width, height);
  }
}
