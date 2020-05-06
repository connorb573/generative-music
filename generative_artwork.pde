import beads.*;
import java.util.ArrayList;
import java.io.IOException;
AudioContext ac; 
int noteCount;
float alpha;
int mode; 
int notesPlaying;
PImage img1;
PImage img2;


//--- Audio Samples ---\\ 
// An object used to manipulate the different samples used in the program as I desire. 
class AudioSample {
  String fileName;
  int note; //Note pitches are stored from 1-12, running from C, Db, ... to B.
  float duration; 
  SamplePlayer player; //The beads samplePlayer associated with the audio file.
  
  private AudioSample(String file, int pitch, float noteDuration, SamplePlayer sp){
    this.fileName = file;
    this.note = pitch;
    this.duration = noteDuration;
    this.player = sp;

  }
  
  public String getFile(){
    return this.fileName;
  }
  
  public void setFile(String name){
    this.fileName = name;
  }
  
  public float getDuration(){
    return this.duration;
  }
  
  public void setDuration(float l){
    this.duration = l;
  }
  
  public int getNote(){
    return this.note;
  }
  
  public void getNote(int i){
    this.note = i;
  }
  
  public SamplePlayer getPlayer(){
    return this.player;
  }
  
  public void setPlayer(SamplePlayer p){
    this.player = p;
  }
  
 }

//----------------\\

//--- Fragments ---\\
//A fragment is a collection of audioSamples, used to create a small melody that repeats as the program is used. 
//Each 'mode' of the program makes use of a collection of fragments, all in the same key, creating harmonious music. 
  class Fragment{
    int noOfNotes;
    int[] notes;
    AudioSample[] instrument;
    Boolean playing;
    int playNo;
    
    private Fragment(int noteNumber, AudioSample[] instrumentType){
      this.noOfNotes = noteNumber;
      this.notes = new int[noteNumber];
      this.instrument = instrumentType;
      this.playing = false;
      this.playNo = 0;
    }
    
    public int getNumberNotes(){
      return this.noOfNotes;   
    }
    
    public void setNumberNotes(int n){
      this.noOfNotes = n;
    }
    
    public int[] getNotes(){
      return this.notes;
    }
    
    public void setNotes(int[] n){
      this.notes = n;
    }
    
    public AudioSample[] getInstrument(){
      return this.instrument;
    }
    
    public void setInstrument(AudioSample[] s){
      this.instrument = s;
    }
    
 }
 
 //---------------------------------------------
 
 //---Colour Square---\\
 //Colour Square objects are used to draw squares onto the image field, these squares have are all initially transparent. 
 //The squares have a relationship with the notes being played such that, each time a note is played, a random square is 'illumintated' with colour for the notes duration. 
 class colourSquare{
   int cornerX;
   int cornerY;
   int sqWidth;
   int sqLength;
   int transparency;
   int colr;
   int colb;
   int colg;
   boolean visible;
   

   
   private colourSquare(int cornX, int cornY, int sWide, int sLong, int alpha, int r, int b, int g){
     cornerX = cornX;
     cornerY = cornY;
     sqWidth = sWide;
     sqLength = sLong;
     transparency = alpha;
     colr = r;
     colb = b;
     colg = g;
     visible = false;
   }
 }
 
//----------------\\


AudioSample[] piano;
AudioSample[] cello;
colourSquare[] squares;
Fragment fragments[];
Gain pianoGain;
Gain celloGain;
Glide pianoVol;
Glide celloVol;
Reverb pianoRev;
Reverb celloRev;
Glide pitch, pitchUp, pitchDown;
Fragment pianoFragment;
AudioSample samples[]; 
ArrayList<String> pianoFileNames;
ArrayList<String> harpFileNames;
File files[];
int time;
int rand; 
boolean notPlaying;
int lastSquare;
float distance;
float button1X, button2X, button3X;
float button1Y, button2Y, button3Y;
float lastMouseX;
float lastMouseY;
AudioSample harp[];

//Loads the samples from the audio files into a respective AudioSample object. 
void loadSamples(AudioSample[] samples)throws IOException {
  SamplePlayer tempSP;
  try{
    if(samples == piano){
    for(int i = 0; i<12; i++){
      tempSP = new SamplePlayer(ac, new Sample(pianoFileNames.get(i)));
      samples[i] = new AudioSample(pianoFileNames.get(i), i+1, 2000, tempSP);  
      samples[i].getPlayer().setKillOnEnd(false);
    }
    }
    else if(samples == harp){
      for(int i = 0; i<3; i++){
      tempSP = new SamplePlayer(ac, new Sample(harpFileNames.get(i)));
      samples[i] = new AudioSample(harpFileNames.get(i), i+1, 2000, tempSP);  
      samples[i].getPlayer().setKillOnEnd(false);

      }
    }
  }
  catch(Exception e){
    println("Exception while loading sample");
    e.printStackTrace();
    exit();
  }
}

//--------------------------------------------------------------------------

//The method that triggers the audio for a specific fragment, each call will trigger one note in the fragment.
//It keeps a track of the which note was played previously and hence, which note to play next, meaning all a fragment's notes are always played in succession. 
void playFragment(Fragment f){
    pianoVol.setValue(random(0.5,2));
    celloVol.setValue(0.05);
    
    if(f == fragments[2]){
       f.getInstrument()[f.getNotes()[f.playNo]].getPlayer().setPitch(pitchDown); //Pitch down for this melody.
     }else 
     if((noteCount % 27 == 0 || noteCount % 19 == 0) && noteCount != 0){
        f.getInstrument()[f.getNotes()[f.playNo]].getPlayer().setPitch(pitchUp); //Pitch up 1 octave everytime the number of notes played is divisible by 27 or 19.
      }
      else if((noteCount % 31 == 0 || noteCount % 45 == 0) && noteCount != 0){
                f.getInstrument()[f.getNotes()[f.playNo]].getPlayer().setPitch(pitchDown); //Pitch down for 31 or 45
      }
      else{
         f.getInstrument()[f.getNotes()[f.playNo]].getPlayer().setPitch(pitch);
      }
      
      f.getInstrument()[f.getNotes()[f.playNo]].getPlayer().setToLoopStart();
      thread("addNote");
      f.getInstrument()[f.getNotes()[f.playNo]].getPlayer().start(); //Play note
      if(f == fragments[1]){
        thread("lightSquareHarp");
      }
      else thread("lightSquare");

      noteCount++;
   
      if(f.playNo + 1 >= f.getNumberNotes()){
       f.playNo = 0;
      }
      else {f.playNo++;}

}

//Method that checks how many notes are playing around the triggering of a new note, 
//this is to stop large overlapping of notes that leads to undesirable audio effects.
void addNote(){
  notesPlaying++;
  delay(1500);
  notesPlaying--;
}

  int lastSquare2;

//Method that illuminates a square with colour when a note is triggered. 
//Begins by checking that the square to be illuminated is not currently visible, and is not the previous square. 
//Then chooses a random colour, and fades in, lights the square for 1.5seconds, and then fades out
void lightSquare(){
  int rand;
  int rand2;
  do{
    rand = (int) random(noOfVLines + 1);
    rand2 = (int)random(noOfHLines + 1);
    
  }while(sqDoubleArray[rand][rand2].transparency > 0 || (rand == lastSquare && rand2 == lastSquare2) );
    lastSquare = rand;
    lastSquare2 = rand2;
    
    sqDoubleArray[rand][rand2].colr = (int)random(10,250);
    sqDoubleArray[rand][rand2].colb = (int)random(10, 250);
    sqDoubleArray[rand][rand2].colg = (int)random(10 ,250);
    delay(500);
    sqDoubleArray[rand][rand2].visible = true;
    delay(1500);
    sqDoubleArray[rand][rand2].visible = false;
    
}

void lightSquareHarp(){
  int rand;
  int rand2;
  do{
    rand = (int) random(noOfVLines + 1);
    rand2 = (int)random(noOfHLines + 1);
    
  }while(sqDoubleArray[rand][rand2].transparency > 0 || (rand == lastSquare && rand2 == lastSquare2) );
    lastSquare = rand;
    lastSquare2 = rand2;
    
    sqDoubleArray[rand][rand2].colr = (int)random(10,250);
    sqDoubleArray[rand][rand2].colb = (int)random(10, 250);
    sqDoubleArray[rand][rand2].colg = (int)random(10 ,250);
    delay(100);
    sqDoubleArray[rand][rand2].visible = true;
    delay(1500);
    sqDoubleArray[rand][rand2].visible = false;
    
}
//----------------------------------------------------------


float decayValue;
float attackValue;
float startPoint2 = 544;
float startPoint3 = 983.0;
float midpoint2 = 696.333;
float midpoint3 = 1100;
//Continously called by the draw method, constantly updates the squares and increases their transparency when visible showing the colour chosen by the lightSquares method. 
void drawSquares(colourSquare[][] arr){
  for(int i =0; i < noOfVLines + 1; i++){
      for(int j = 0; j< noOfHLines + 1; j++){
    if(arr[i][j].visible == true){
        attackValue = (button2X - startPoint2)/20;
        if(attackValue < 1)
          attackValue = 1;
      if(arr[i][j].transparency < 150){
      arr[i][j].transparency +=attackValue;
      }
    }
     if(arr[i][j].visible == false){
       if(button3X <= startPoint3){
         decayValue = 1/20;
       }
       else
         decayValue = (button3X - startPoint3)/50;
      // //if(button3X > 1100){
      //  decayValue = (button3X - midpoint3)/5;
      // }
      //  else 
      //  decayValue = 1/((midpoint3 - button3X)/5);
      if(arr[i][j].transparency > 0)
       arr[i][j].transparency -= decayValue;
    }
      
    fill(arr[i][j].colr, arr[i][j].colb, arr[i][j].colg, arr[i][j].transparency);
    rect(arr[i][j].cornerX, arr[i][j].cornerY, arr[i][j].sqWidth, arr[i][j].sqLength);
  }
 }
 }
   float button3XStart;
void setup(){
  fullScreen();
  ac = new AudioContext();
  piano = new AudioSample[12];
  harp = new AudioSample[12];
  notPlaying = true;
  rand = 255;
  noteCount = 0;
  alpha = 0;
  mode = 2; 
        
   distance = width/2.7 - (width/17 + (width/3 - width/10));
   button1X = -5 + (width/17 + (width/17 + (width/3 - width/10)))/2;
   button2X = -5 + (width/2.7 + (width/2.7 + width/3 - width/10))/2;
   button3X = -5 + ((width/2.7 + (width/3 - width/10) + distance) + (width/2.7 
              + (width/3 - width/10) + distance) + (width/3 - width/10))/2;
   button3XStart = button3X;
   button1Y = height/25;
   button2Y = height/25;
   button3Y = height/25;
  
  lastMouseX = 0;
  
  //Load in files for Piano
  pianoFileNames = new ArrayList<String>(); 
  harpFileNames = new ArrayList<String>();
  for(int i =0; i<12; i++){
   pianoFileNames.add(sketchPath("") + "Samples/PianoKeySamples/" + (i+1) + ".wav");
  }
  for(int i = 0; i < 3; i++){
      harpFileNames.add(sketchPath("")+ "Samples/HarpSamples/" + (i+1) + ".wav");
  }
   //loadFile(pianoFileNames);
 
    try{
      loadSamples(piano);
      loadSamples(harp);
    }
    catch(Exception e){
      println("Exception while loading sample");
      e.printStackTrace();
      exit();    
    }
    
    pianoVol = new Glide(ac, 0.0, 20);
    pianoGain = new Gain(ac, 1, pianoVol);
    
    pianoRev = new Reverb(ac, 1);
    pianoRev.setSize(0.9);
    pianoRev.setDamping(0.1);
    
    celloVol = new Glide(ac, 0.0, 30);
    celloGain = new Gain(ac, 1, celloVol);
    
    celloRev = new Reverb(ac, 1);
    celloRev.setSize(0.9);
    celloRev.setDamping(0.1);
    
    pitchUp = new Glide(ac, 2);
    pitch = new Glide(ac, 1);
    pitchDown = new Glide(ac, 0.5);
  
    for(int i = 0; i<12; i++){
      pianoGain.addInput(piano[i].getPlayer());
    }
    
    for(int i = 0; i<3; i++){
      celloGain.addInput(harp[i].getPlayer());
    }
    
    pianoRev.addInput(pianoGain);
    ac.out.addInput(pianoRev);
    ac.out.addInput(pianoGain);
    pianoVol.setValue(0);
    
    celloRev.addInput(celloGain);
    ac.out.addInput(celloRev);
    ac.out.addInput(celloGain);
    celloVol.setValue(0);
    
    fragments = new Fragment[4];
    int notes1[] = new int[3];
    notes1[0] = 0;
    notes1[1] = 11;
    notes1[2] = 7;
    
    int notes2[] = new int[3];

    notes2[0] = 0; //F
    notes2[1] = 1; //E 
    notes2[2] = 2; //A 
   
    fragments[0] = new Fragment(3, piano);
    fragments[0].setNotes(notes1);
    
    fragments[1] = new Fragment(3, harp);
    fragments[1].setNotes(notes2);
    
    fragments[2] = new Fragment(4, piano);
    
    int notes3[] = new int[4];
    notes3[0] = 0;
    notes3[1] = 5;
    notes3[2] = 4;
    notes3[3] = 7;
    
    fragments[2].setNotes(notes3);
    
    int notes4[] = new int[4];
    notes4[0] = 2;
    notes4[1] = 10;
    notes4[2] = 9;
    notes4[3] = 5;
    
    fragments[3] = new Fragment(4, piano);
    fragments[3].setNotes(notes4);
    
    initialiseLines();
    createSquares();
    ac.start();
    background(255);
}
    
float tempoFactor; //<>//
int loop1Factor;
int loop2Factor;
int loop3Factor;
void draw(){
  
    time = millis();
    println(time);
    background(255, 255, 255);
    
    strokeWeight(8);
   drawShapes();
   drawSquares(sqDoubleArray);
   tempoFactor = (button1X - 84)/100;
   loop1Factor = (int) (293 * 1/tempoFactor);
   loop2Factor = (int) (383 * 1/tempoFactor);
   loop3Factor = (int) (454 * 1/tempoFactor);  
    
    
    //D C# A G
    if(time > 10000){
      if(notesPlaying < 5){
      if(time % loop1Factor == 0){
        thread("playFrag0");
      }
      
      if(time % loop2Factor == 0){
        thread("playFrag1");
      }
      
      if(time % loop3Factor ==0){
        thread("playFrag2");
      }
      }
    }
    
    //Draws the menu boxes at the top and bottom of the screen
    ///////////////////////////////////////////////////////
    if(mouseY < height/7){
      if(alpha < 150){
        alpha += 5;
      }
      fill(204,204,204, alpha);
      strokeWeight(0.5);
      rect(0,0, width, height/7);
      
      //Slider bars
      rect(width/17 , height/15, (width/3 - width/10), height/50);
      rect(width/2.7, height/15, (width/3 - width/10), height/50);
      rect(width/2.7 + (width/3 - width/10) + distance, height/15, (width/3 - width/10), height/50);
      
      fill(255);
      strokeWeight(1);
      if(pressed1){
        if(mouseX >= width/17 && mouseX < width/17 + (width/3 - width/10)){
          button1X = mouseX;
          
        }
      }
      
      if(pressed2){
        if(mouseX >= width/2.7 && mouseX < width/2.7 + (width/3 - width/10)){
          button2X = mouseX;
        }
      }
      
       if(pressed3){
        if(mouseX >= width/2.7 + (width/3 - width/10) + distance && mouseX < width/2.7 + (width/3 - width/10) + distance + (width/3 - width/10)){
          button3X = mouseX;
        }
      }
      
      
      
      rect(button1X, button1Y, width/60, height/14);
      rect(button2X, button2Y, width/60, height/14);
      rect(button3X, button3Y, width/60, height/14);
      
      String strings[] = {"Tempo", "Attack", "Decay", "Reset"};
      
      fill(0, 0, 0, alpha);
      text(strings[0], width/6, height/60, width/17 + width/50, height/20 + height/14);
      text(strings[1], 3*width/6 - 30, height/60, width/17 + width/50, height/20 + height/14);
      text(strings[2], 5*width/6 - 60, height/60, width/17 + width/50, height/20 + height/14);
      text(strings[3], width/50, height/50, width/50 + width/50, height/50 + height/14);

    }
  
      if( 6*height/7 > mouseY && mouseY > height/7){
      alpha = 0;
    }
     //////////////////////////////////////////////////////
     
}
boolean pressed1, pressed2, pressed3;
void mousePressed(){
  if(mouseX > button1X && mouseX < button1X + width/60
      && mouseY > button1Y && mouseY < button1Y + height/14){
       pressed1 = true;
  }
  
  if(mouseX > button2X && mouseX < button2X + width/60 
    && mouseY > button2Y && mouseY < button2Y + height/14){
      pressed2 = true;
    }
    
    if(mouseX > button3X && mouseX < button3X + width/60 
    && mouseY > button3Y && mouseY < button3Y + height/14){
      pressed3 = true;
    }
}

void mouseClicked(){
  if(mouseX > width/50 && mouseY > height/50 && mouseX < width/50 + width/50 && mouseY < height/50 + height/14){
    initialiseLines();
     createSquares();
  }
}

void mouseReleased(){
  pressed1 = false;
  pressed2 = false;
  pressed3 = false;
}

//Methods used to start fragment playing, sperated like this as they have to be called on new threads. 
void playFrag0(){
    
          playFragment(fragments[0]);

         
}

void playFrag1(){
    
          playFragment(fragments[1]);

         
}

void playFrag2(){
    
          playFragment(fragments[2]);

}

void playFrag3(){
    
          playFragment(fragments[3]);

         
}

//This method draws the scene.
void drawShapes(){
  for(int i =0; i<noOfVLines + 1; i++){
    line(linesV[i][0], linesV[i][1], linesV[i][2], linesV[i][3]);
  }
  
  for(int i = 0; i<noOfHLines + 1; i++){
    line(linesH[i][0], linesH[i][1], linesH[i][2], linesH[i][3]);
  }
    
}

//NOTE: All of the noOfLines + 1 - the plus one accomodates for the far edge lines, needed to make the edge boxes light up.
colourSquare sqDoubleArray[][];
void createSquares(){
  sqDoubleArray = new colourSquare[noOfVLines + 1][noOfHLines + 1];
  
  //vertical lines 
  for(int i =0; i < noOfVLines + 1; i++){
    if(i == 0){
      for(int j = 0; j<noOfHLines + 1; j++){
        if(j == 0){
          sqDoubleArray[i][j] = new colourSquare(linesV[i][0], linesH[j][1], -linesV[i][0], -linesH[j][1], 0,0,0,0);
        }
        else {
          sqDoubleArray[i][j] = new colourSquare(linesV[i][0], linesH[j][1], -linesV[i][0], linesH[j-1][1] - linesH[j][1], 0,0,0,0);
        }
        
      }
    }
    else {
      for(int j = 0; j<noOfHLines + 1; j++){
        if(j == 0){
          sqDoubleArray[i][j] = new colourSquare(linesV[i][0], linesH[j][1], linesV[i - 1][0] - linesV[i][0], -linesH[j][1], 0,0,0,0);
        }
        else {
          sqDoubleArray[i][j] = new colourSquare(linesV[i][0], linesH[j][1], linesV[i - 1][0] - linesV[i][0],linesH[j-1][1] - linesH[j][1], 0,0,0,0);
        }
      }
  }
  
}
}

int totalLines;
int noOfVLines;
int noOfHLines;
int vLinesWidth[];
int hLinesHeight[];
int linesV[][];
int linesH[][];


//This method initialises the coordinates of the lines on the screen, from which the squares are generated. 
void initialiseLines(){
  totalLines = (int)random(6,9);
  noOfVLines = (int)random(totalLines/3, (totalLines - random(1, totalLines/2)));
  noOfHLines = totalLines - noOfVLines;
  linesV = new int[noOfVLines + 1][4];
  linesH = new int[noOfHLines + 1][4];
  
  vLinesWidth = new int[noOfVLines + 1];
  hLinesHeight = new int[noOfHLines + 1];
  
   randArr = new int[noOfVLines];
  
  recreateRandArr();
  orderRandArr();
  
  int last = 0;
  for(int i = 0; i<noOfVLines; i++){
  
        vLinesWidth[i] = randArr[i];
   
    last = vLinesWidth[i];
  
    
      linesV[i][0] = width * vLinesWidth[i]/10;
      linesV[i][1] = 0;
      linesV[i][2] = linesV[i][0];
      linesV[i][3] = height;
      
  }
  linesV[noOfVLines][0] = width;
  linesV[noOfVLines][1] = 0;
  linesV[noOfVLines][2] = linesV[noOfVLines][0];
  linesV[noOfVLines][3] = height;
  
  randArr = new int[noOfHLines];
 recreateRandArr();
 orderRandArr();
  
  last = 0;
  for(int i = 0; i<noOfHLines; i++){
   
      hLinesHeight[i] = randArr[i];

    last = hLinesHeight[i];
    
      linesH[i][0] = 0;
      linesH[i][1] = height * hLinesHeight[i]/10;
      linesH[i][2] = width;
      linesH[i][3] = height * hLinesHeight[i]/10;
  }
  linesH[noOfHLines][0] = 0;
  linesH[noOfHLines][1] = height;
  linesH[noOfHLines][2] = width;
  linesH[noOfHLines][3] = height;
}

float squaresV[][];
float squaresH[][];
float widthIncrease;
float heightIncrease;
int rand2;
colourSquare sqArray[];

int[] randArr;
int[] resultArr;
int[] checkedArr;

void recreateRandArr(){
  for(int i = 0; i<randArr.length; i++){
    if(i == 0){
      randArr[i] = (int)random(1,10);
    }
    if(i == 1){
      do{
        randArr[1] = (int)random(1,10);
      
      }while(randArr[i] == randArr[0]);
    }
    
    if(i == 2){
      do{
        randArr[i] = (int)random(1,10);
      }while(randArr[2] == randArr[0] || randArr[2] == randArr[1]);
    }
    
    if(i == 3){
      do{
        randArr[i] = (int)random(1,10);
      }while(randArr[3] == randArr[0] || randArr[3] == randArr[1] || randArr[3] == randArr[2] );
    }
    
    if(i == 4 ){
      do{
        randArr[i] = (int)random(1,10);
      }while(randArr[4] == randArr[0] || randArr[4] == randArr[1] || randArr[4] == randArr[2] || randArr[4] == randArr[3]);
    }
    
    if(i == 5){
      do{
        randArr[i] = (int)random(1,10);
      }while(randArr[5] == randArr[0] || randArr[5] == randArr[1] || randArr[5] == randArr[2] || randArr[5] == randArr[3] || randArr[5] == randArr[4]);
    }
    
    if(i == 6){
      do{
        randArr[i] = (int)random(1,10);
      }while(randArr[i] == randArr[0] || randArr[6] == randArr[1] || randArr[6] == randArr[2] || randArr[6] == randArr[3] || randArr[6] == randArr[4] || randArr[6] == randArr[5]);
     }
     
     if(i == 7){
      do{
        randArr[i] = (int)random(1,10);
      }while(randArr[i] == randArr[0] || randArr[7] == randArr[1] || randArr[7] == randArr[2] || randArr[7] == randArr[3] || randArr[7] == randArr[4] || randArr[7] == randArr[5] || randArr[7] == randArr[6]); 
     }
}
}

void orderRandArr(){
  for (int j = 1; j < randArr.length; j++) {
    int key = randArr[j]; int i = j-1;
    while ( (i > -1) && ( randArr[i] > key ) ) { 
      randArr[i+1] = randArr[i]; i--; 
    }
  randArr[i+1] = key;
  }
}




   
   
