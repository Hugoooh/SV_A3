public class CheckBox {
  String text;
  float x, y;
  boolean checked, visible, isHovering;
  
  color highlightColor;
  
  static final int size = 14;
  static final int padding = 7;
  
  CheckBox(String _text, float _x, float _y) {
    x = _x;
    y = _y;
    text = _text;
    
    highlightColor = color(80);
    visible = true;
    checked = isHovering = false;
    
    Interactive.add(this);
  }
  
  void mouseReleased() {
    if (!visible) {
      return;
    }
    
    checked = !checked;
  }
  
  void mouseEntered() {
    isHovering = true;
  }

  void mouseExited() {
    isHovering = false;
  }
  
  void draw() {
    if (!visible) {
      return;
    }
    
    fill(isHovering ? 175 : 200);
    stroke(20);
    strokeWeight(1);
    rect(x, y, size, size);
    
    if (checked) {
      noStroke();
      fill(highlightColor);
      rect(x + 4, y + 4, size - 7, size - 7);
    }
    
    fill(0);
    textAlign(LEFT, CENTER);
    text(text, x + size + 7, y + size / 2);
  }

  boolean isInside(float mx, float my) {
    return visible && Interactive.insideRect(x, y, size + padding + textWidth(text), size, mx, my);
  }
}
