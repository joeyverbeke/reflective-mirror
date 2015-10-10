import gab.opencv.*;
import processing.video.*;
import java.awt.*;

Capture video;
OpenCV opencv;
int timeSinceFaceLost = 0;
int timeSinceFaceAppeared = 0;
int NUM_FRAMES_TO_ALLOW_SAVED_PICTURE = 5; //probably changes these to be time based instead of frame
int NUM_FRAMES_TO_ALLOW_NEW_SAVED_FACE = 20;
PImage previousFace;
PImage possibleNewFace;
PImage[] previousFaces = new PImage[50];

PGraphics mask;
PImage displayedFace;

boolean USE_LIVE_VIDEO_AS_MIRROR = true;
boolean GIF_INSTEAD_OF_PIC = true;

int faceGifCounter = 0;
PImage[] possibleNewFaceGif = new PImage[5];
PImage[] previousFaceGif = new PImage[5];

void setup() {
  size(640, 480);
  video = new Capture(this, 640/2, 480/2);
  opencv = new OpenCV(this, 640/2, 480/2);
  //  video = new Capture(this, 640, 480);
  //  opencv = new OpenCV(this, 640, 480);  

  opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);  

  frameRate(5);

  previousFace = loadImage("test.tif");
  possibleNewFace = loadImage("test.tif");
  for (int i=0; i<previousFaces.length; i++)
    previousFaces[i] = loadImage("test.tif");
    
  for (int i=0; i<previousFaceGif.length; i++)
    previousFaceGif[i] = loadImage("test.tif");
  for (int i=0; i<possibleNewFaceGif.length; i++)
    possibleNewFaceGif[i] = loadImage("test.tif");


  video.start();
}

void draw() {
  //  scale(2);

  translate(640, 0);
  scale(-2, 2);
  opencv.loadImage(video);

  image(video, 0, 0 );
  //  PImage camVid;
  //  camVid = video;


  noFill();
  //  stroke(0, 255, 0);
  //  strokeWeight(3);
  Rectangle[] faces = opencv.detect();
  println(faces.length);

  if (faces.length > 0) {
    fill(0, 0, 0);
    rect(0, 0, 320, 240);
  }

  int faceX, faceY = 0;

  for (int i = 0; i < faces.length; i++) {
    println(faces[i].x + "," + faces[i].y);
    PImage onlyFace = video.get(faces[i].x, faces[i].y, faces[i].width, faces[i].height);
    //    image(onlyFace, faces[i].x, faces[i].y);

    //save face every frame until face is lost
    if (timeSinceFaceLost == 0)
      onlyFace.save("test");

    //load each face/frame into array
    print("timeSinceFaceAppeared(inLoop): " + timeSinceFaceAppeared + '\n');
    previousFaces[timeSinceFaceAppeared%50] = loadImage("test.tif");

    if(GIF_INSTEAD_OF_PIC)
      previousFace = previousFaceGif[faceGifCounter];

/*  //for glitching current camera feed of face
    int index;
    if(timeSinceFaceAppeared < 5)
      index = timeSinceFaceAppeared % 50;
    else
      index = (timeSinceFaceAppeared - faceGifCounter) % 50;
*/
    
//    PImage transfer = previousFaces[timeSinceFaceAppeared%50].get();
//    transfer.resize(previousFace.width, previousFace.height);

    PImage transfer = createImage(previousFace.width, previousFace.height, RGB);
    transfer.copy(previousFaces[timeSinceFaceAppeared%50], 0, 0, previousFaces[timeSinceFaceAppeared%50].width, previousFaces[timeSinceFaceAppeared%50].height,
                                                           0, 0, transfer.width, transfer.height);
  
    transfer.loadPixels();
    previousFace.loadPixels();
    for (int j=0; j < previousFace.width * previousFace.height; j++)
    {
      if (j%previousFace.width < previousFace.width/2) {
        //put this back for mirror because don't need camera feed
        if(USE_LIVE_VIDEO_AS_MIRROR)
          previousFace.pixels[j] = transfer.pixels[j];
        else
          previousFace.pixels[j] = color(0, 0, 0, 1);
      }
    }
    previousFace.updatePixels();

//    PImage displayAsEllipse= previousFace.get();
//    displayAsEllipse.resize(faces[i].width, faces[i].height);
    PImage displayAsEllipse = createImage(faces[i].width, faces[i].height, RGB);
    displayAsEllipse.copy(previousFace, 0, 0, previousFace.width, previousFace.height, 
                                        0, 0, displayAsEllipse.width, displayAsEllipse.height);



    //    image(previousFace, faces[i].x, faces[i].y, faces[i].width, faces[i].height);


    noFill();
    ellipseMode(CORNERS);
    stroke(0, 0, 0);
    strokeWeight(1);
    ellipse(faces[i].x, faces[i].y, faces[i].x + faces[i].width, faces[i].y + faces[i].height);

    stroke(0, 0, 0);

    ////////////
    //change to previousImage for mirror
    displayedFace = displayAsEllipse;

    mask=createGraphics(displayedFace.width, displayedFace.height);//draw the mask object
    mask.beginDraw();
    mask.smooth();//this really does nothing, i wish it did
    mask.background(0);//background color to target
    mask.fill(255);
    //  ellipseMode(CORNERS);
    mask.ellipse(displayedFace.width/2, displayedFace.height/2, displayedFace.width, displayedFace.height);
    mask.endDraw();

    displayedFace.mask(mask);
    image(displayedFace, faces[i].x, faces[i].y);
    /////////////
    
    if(faceGifCounter >= previousFaceGif.length-1)
      faceGifCounter = 0;
    else
      faceGifCounter++;
  }

  if (faces.length > 0) {
    timeSinceFaceLost = 0;
    timeSinceFaceAppeared++;
  } else if (faces.length == 0) {

    print("NO FACES" + '\n');
    print("timeSinceFaceLost inside: " + timeSinceFaceLost + '\n');
    print("timeSinceFaceAppeared inside: " + timeSinceFaceAppeared + '\n');
    //face was just lost
    if (timeSinceFaceAppeared > NUM_FRAMES_TO_ALLOW_SAVED_PICTURE) {
      //      previousFace = previousFaces[(timeSinceFaceAppeared-5)%50];
      possibleNewFace = previousFaces[(timeSinceFaceAppeared-5)%50];
      
      for(int i=0; i<possibleNewFaceGif.length; i++){
        possibleNewFaceGif[i] = previousFaces[Math.abs(timeSinceFaceAppeared-5 - possibleNewFaceGif.length-i)%50];
      }
    }

    timeSinceFaceLost++;
    timeSinceFaceAppeared = 0;

    if (timeSinceFaceLost > NUM_FRAMES_TO_ALLOW_NEW_SAVED_FACE) {
      previousFace = possibleNewFace;
      
      for(int i=0; i<previousFaceGif.length; i++){
        previousFaceGif[i] = possibleNewFaceGif[i];
      }
    }
  }

  /*
  noFill();
   beginShape();
   vertex(50, 50);
   bezierVertex(50, 50, 70, 70, 50, 90);
   bezierVertex(50, 20, 30, 30, 50, 90);
   endShape();
   */


  print("numFaces: " + faces.length + '\n');
  print("timeSinceFaceLost: " + timeSinceFaceLost + '\n');
  print("timeSinceFaceAppeared: " + timeSinceFaceAppeared + '\n');
  print("frameRate: " + frameRate + '\n' + '\n');
  print();
}

void captureEvent(Capture c) {
  c.read();
}

