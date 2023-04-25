// Import controlP5 library for creating graphical user interfaces
import controlP5.*;

// Declare global variables
float DAMPENING = 0.99;
float RAND_X = 0;
float RAND_Y = 0;
float MAX_SIZE = 0.003;
float MIN_SIZE = 0.00003;
int COLUMNS = 10;
int ROWS = 10;
float G = 6;
boolean TORUS = true;
float MASS_FACTOR = 30000;
float TRAIL_LENGTH = 8;
float OPACITY = 255;
float S_COLOR = 0;
float S_ALPHA = 64;
boolean TRAIL = false;
boolean SAVE_MOVIE = false;
boolean STROKE = false;
boolean RANDOM = true;
boolean GRID = false;
boolean PLANET = true;
boolean DRAW_LINES = false;
float DRAW_MASS = 0.3;

// Member class definition
class Member {
  int index;
  int distIndex;
  float mass;
  PVector position;
  PVector velocity;
  PVector acceleration;
  float distance;
  float red;
  float green;
  float blue;

  // Draw the Member
  void draw() {
    float diameter = 0;
    diameter = sqrt((mass/3.14) * MASS_FACTOR) * velocity.mag();
    red = map(abs(velocity.mag()), 0, .6, 64, 128);
    green = map(abs(velocity.mag()), 0, 6, 64, 255);
    blue = map(abs(acceleration.mag()), 0, .02, 0, 255);
    fill(red, green, blue, OPACITY);
    noStroke();
    if(PLANET) ellipse(position.x, position.y, diameter, diameter);   
    reset();
  }
  
  // Reset the Member's acceleration and distance
  void reset(){
    acceleration.set(0, 0);
    distance = width + height;
  }

  // Check and adjust the Member's position if it goes out of the screen
  void checkBoundaries(){
    if (position.x > width) position.x -= width;
    if (position.x <= 0) position.x += width;
    if (position.y > height) position.y -= height;
    if (position.y <= 0) position.y += height;
  }

  // Initialize the Member's properties
  void init() {
    position = new PVector(0, 0);
    velocity = new PVector(0, 0);
    acceleration = new PVector(0, 0);
    mass = random(MIN_SIZE, MAX_SIZE);
    index = 0;
    red = 0;
    green = 0;
    blue = 0;
    distIndex = -1;
    distance = width + height;
  }

  // Member constructor for the mouse location
  Member() { 
    init();
    position.x = mouseX;
    position.y = mouseY;
  }

  // Member constructor with specific position
  Member(float x, float y) {
    init();
    position.x = x;
    position.y = y;
  }
}

// Swarm class definition
class Swarm {
  ArrayList<Member> member;

  // Initialize the swarm with Members
  void init(){
    for (int x = 0; x < COLUMNS; x++) {
      for (int y = 0; y < ROWS; y++) {
        if(RANDOM) swarm.addMember(random(width), random(height));
        if(GRID) swarm.addMember((x + 0.5)*width/COLUMNS, (y + 0.5)*height/ROWS);
      }
    }
  }
  // Add a new Member to the swarm
  void addMember() {
    member.add(new Member());
    bodies.setText(str(member.size()));
    member.get(member.size() - 1).index = member.size() - 1;
  }

  // Add a new Member to the swarm at a specific position
  void addMember(float x, float y) {
    addMember();
    member.get(member.size() - 1).position.x = x;
    member.get(member.size() - 1).position.y = y;
  }
  
  // Update the acceleration between two Members
  void updateAcceleration(Member m1, Member m2) {
    if (m1.index != m2.index) calculateGravity(m1, m2, 0, 0);

    if (TORUS == true) {
      calculateGravity(m1, m2, width, 0);
      calculateGravity(m1, m2, -width, 0);
      calculateGravity(m1, m2, 0, height);
      calculateGravity(m1, m2, 0, -height);
    }
  }
  
  // Calculate the gravity force between two Members considering the offset
  void calculateGravity(Member m1, Member m2, float offsetX, float offsetY){
    PVector vDist = new PVector(0, 0);
    PVector mTemp = new PVector(0, 0);
    float distance = 0;
    float force = 0;
    mTemp.add(m2.position).add(offsetX, offsetY);
    vDist = PVector.sub(mTemp, m1.position);
    distance = mTemp.dist(m1.position);  
    force = (G * m1.mass * m2.mass) / (distance * distance) * DAMPENING;
    m1.acceleration.add(vDist.mult(force)).add(random(-RAND_X, RAND_X), random(-RAND_Y, RAND_Y));
  }

  // Update the velocity of a Member
  void updateVelocity(Member m1) {m1.velocity = m1.velocity.add(m1.acceleration.div(m1.mass)).mult(DAMPENING);}

  // Update the position of a Member
  void updatePosition(Member m1) {
    m1.position.add(m1.velocity);
    if (TORUS == true) m1.checkBoundaries();
  }
  
  // Get the data for drawing lines between Members
  void getLineData(int m1, int m2){
    float d = abs(member.get(m1).position.dist(member.get(m2).position));
    if(d < member.get(m1).distance) {member.get(m1).distance = d; member.get(m1).distIndex = m2;}
    if(d < member.get(m2).distance) {member.get(m2).distance = d; member.get(m2).distIndex = m1;}
  }
  
  // Update the swarm's state
  void update() {
    for (int m1 = 0; m1 < member.size(); m1++) {
      for (int m2 = m1 + 1; m2 < member.size(); m2++) {
        getLineData(m1, m2);
        swarm.updateAcceleration(member.get(m1), member.get(m2));
        swarm.updateAcceleration(member.get(m2), member.get(m1));
      }
      swarm.updateVelocity(member.get(m1));
      swarm.updatePosition(member.get(m1));
    }
  }
  
  // Draw lines between Members
  void drawLines(){
    for(Member m : member){
      float red = (m.red + member.get(m.distIndex).red) / 2;
      float green = (m.green + member.get(m.distIndex).green) / 2;
      float blue = (m.blue + member.get(m.distIndex).blue) / 2;
      float opacity = 16;
      stroke(red, green, blue, opacity);
      line(m.position.x, m.position.y, member.get(m.distIndex).position.x, member.get(m.distIndex).position.y);
    }
  }

  // Draw the swarm
  void draw() {
    if(DRAW_LINES)drawLines();
    for (Member m : member) {
      m.draw();
    }
  }

  Swarm() {member = new ArrayList<Member>();}
}

ControlP5 gui;

// GUI components
Slider gravity;
Slider dampening;
Slider trailLength;
Slider opacity;
Textarea bodies;

Swarm swarm = new Swarm();

// Initialize the graphical user interface
void guiSetup(){
  gui = new ControlP5(this);
  
  bodies = gui.addTextarea("txt")
  .setPosition(width / 2, height - 20)
  .setSize(40,40)
  .setFont(createFont("arial",12))
  .setLineHeight(14)
  .setColor(color(128))
  .setColorBackground(color(0,100))
  .setColorForeground(color(0,100));
  ;

  gravity = gui.addSlider("G")
  .setCaptionLabel("Gravity")
  .setRange(-10, 10)
  .setValue(5)
  .setPosition(10,10)
  .setWidth(200)
  ;

  dampening = gui.addSlider("DAMPENING")
  .setCaptionLabel("Dampening")
  .setRange(0.99, 1.0)
  .setValue(0.999)
  .setPosition(10,20)
  .setWidth(200)
  ;

  trailLength = gui.addSlider("TRAIL_LENGTH")
  .setCaptionLabel("Trail Length")
  .setRange(0, 255)
  .setValue(8)
  .setPosition(10,30)
  .setWidth(200)
  ;

  opacity = gui.addSlider("OPACITY")
  .setCaptionLabel("Opacity")
  .setRange(0, 255)
  .setValue(255)
  .setPosition(10,40)
  .setWidth(200)
  ;

  gui.addToggle("TRAIL")
  .setCaptionLabel("Trails")
  .setPosition(280,10)
  .setSize(20,20)
  .setValue(true)
  ;

  gui.addToggle("TORUS")
  .setCaptionLabel("Torus")
  .setPosition(320,10)
  .setSize(20,20)
  .setValue(true)
  ;

  gui.addToggle("STROKE")
  .setCaptionLabel("Stroke")
  .setPosition(360,10)
  .setSize(20,20)
  .setValue(false)
  ;

  gui.addToggle("BOUNCE")
  .setCaptionLabel("Stroke")
  .setPosition(400,10)
  .setSize(20,20)
  .setValue(false)
  ;

  gui.addButton("Clear")
  .setValue(0)
  .setPosition(440, 10)
  .setSize(20, 20)
  ;
}

void setup() {
  //size(1024, 1024);
  fullScreen();
  background(0);
  guiSetup();
  swarm.init();
}

// Clear the swarm
public void Clear() {
  swarm.member.clear();
  background(0);
  bodies.setText("0");
}

// Set the drawing options
void drawingOptions(){
  if(TRAIL){
    fill(0, TRAIL_LENGTH);
    rect(0, 0, width, height);
  }else{
    background(0);
  }
  if(!STROKE) {noStroke();}else{stroke(S_COLOR, S_ALPHA);}
}

// Apply brush effect when right mouse button is pressed
void brush(){
  Member m2 = new Member();
  m2.position.x = mouseX;
  m2.position.y = mouseY;
  m2.mass = DRAW_MASS;
  for(Member m : swarm.member){
    swarm.updateAcceleration(m, m2);
  }
}

void mousePressed(){
  if(mouseButton == RIGHT){
    brush();
  }else{
    if(!gui.isMouseOver()) swarm.addMember();
  }
}

void mouseDragged(){
  if(mouseButton == RIGHT){
    brush();
  }else{
    if(!gui.isMouseOver()) swarm.addMember();
  }
}

void draw() {
  drawingOptions();
  swarm.update();
  swarm.draw();
  gui.draw();
  if(SAVE_MOVIE)saveFrame("C:/Users/Esikich/Documents/Processing/Frames/1-#####.tif");
}
