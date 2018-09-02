// Paolo Pasteris
// Light Budda

import org.openkinect.freenect.*;
import org.openkinect.processing.*;
import processing.video.*;
import processing.sound.*;
import blobDetection.*;

BlobDetection theBlobDetection;
int previuosBlobNumber;
float blobTh;
float blobAreaTh;

ArrayList<SoundFile> sounds = new ArrayList<SoundFile>();
Movie myMovie;
Kinect kinect;

String backgroundName = "backgorund.mp4";
boolean enableFullScreen = false;
float whidthTH = 600000.0f;//at least 50 px

// Depth image
PImage depthImg;
PImage staticMask;
PImage kinectMask;

// Which pixels do we care about?
int minDepth =  60;
int maxDepth = 860;

// What is the kinect's angle
float angle;

void setup() {
  
  fullScreen(JAVA2D);
  //size(640,480);
  
  kinect = new Kinect(this);
  kinect.initDepth();
  angle = kinect.getTilt();

  // Blank image
  depthImg = new PImage(kinect.width, kinect.height);
  
  myMovie = new Movie(this, backgroundName);
  //myMovie.play();
  myMovie.loop();
  
  for(int i=0; i < 8 ;++i)
  {
    sounds.add( new SoundFile(this, "0"+i+".mp3"));
  }
  
  theBlobDetection = new BlobDetection(kinect.width, kinect.height);
  blobTh = 0.10f;
  theBlobDetection.setThreshold(blobTh);
  previuosBlobNumber = 0;
  blobAreaTh = 70000.0f;
}

void draw() {
  background(0);
  // Draw the raw image
  //image(kinect.getDepthImage(), 0, 0);

  // Threshold the depth image
  int[] rawDepth = kinect.getRawDepth();
  for (int i=0; i < rawDepth.length; i++) {
    if (rawDepth[i] >= minDepth && rawDepth[i] <= maxDepth) {
      depthImg.pixels[i] = color(255);
    } else {
      depthImg.pixels[i] = color(0);
    }
  }

  // Draw the thresholded image
  depthImg.updatePixels();
  theBlobDetection.computeBlobs(depthImg.pixels);
  //drawBlobsAndEdges(true, true);
  
  
  //if( theBlobDetection.getBlobNb() != previuosBlobNumber)
  if( getBlobs() != previuosBlobNumber )
  {
    previuosBlobNumber = getBlobs();
    sounds.get(int(random(8))).play();
    //sounds.get(2).play();
  }
  
  if(myMovie.width > 0 
  && myMovie.height > 0)
  {
    kinectMask = new PImage(myMovie.width,myMovie.height);
    kinectMask.copy(depthImg,0,0,kinect.width,kinect.height,0,0,myMovie.width,myMovie.height);
    //image(kinectMask, 0, 0);
    //println("KinectMask: "+kinectMask.width+" "+kinectMask.height);
    //println("depthImg: "+depthImg.width+" "+depthImg.height);
    myMovie.mask(kinectMask);
    image(myMovie, 0, 0);
  }
    
  fill(255,0,0);
  text("TILT: " + angle, 10, 20);
  text("THRESHOLD: [" + minDepth + ", " + maxDepth + "]", 10, 36);
  text("BLOB: ["+previuosBlobNumber+ "]", 10, 46);
  text("BLOB_TH: ["+blobTh+ "]", 10, 56);
}

// Adjust the angle and the depth threshold min and max
void keyPressed() {
  if (key == CODED) {
    if (keyCode == UP) {
      angle++;
    } else if (keyCode == DOWN) {
      angle--;
    }
    angle = constrain(angle, 0, 30);
    kinect.setTilt(angle);
  } else if (key == 'a') {
    minDepth = constrain(minDepth+10, 0, maxDepth);
  } else if (key == 's') {
    minDepth = constrain(minDepth-10, 0, maxDepth);
  } else if (key == 'z') {
    maxDepth = constrain(maxDepth+10, minDepth, 2047);
  } else if (key =='x') {
    maxDepth = constrain(maxDepth-10, minDepth, 2047);
  } else if (key == 'q') {
    blobTh = constrain(blobTh+0.10f, 0.0f, 1.0f);
    theBlobDetection.setThreshold(blobTh);
  } else if (key =='w') {
    blobTh = constrain(blobTh-0.10f, 0.0f, 1.0f);
    theBlobDetection.setThreshold(blobTh);
  } else if (key =='p') {
    sounds.get(int(random(8))).play();
  }
  
}

void movieEvent(Movie m) {
  m.read();
}

boolean isWhite(PImage image)
{
  int dimension = image.width * image.height, sum = 0;
  color c;
  for (int i = 0; i < dimension; i += 2) { 
    c = image.pixels[i];
    if( ((c >> 16 & 0xFF)+(c >> 8 & 0xFF)+(c & 0xFF)) > 10 )
      ++sum;
  }
  //println(sum);
  return (sum > whidthTH ? true : false);
}

int getBlobs()
{
  Blob b;
  int retVal = 0;
  for (int n=0 ; n<theBlobDetection.getBlobNb() ; n++)
  {
    b=theBlobDetection.getBlob(n);
    if (b!=null)
    {
      if( (b.w*kinect.width)*(b.h*kinect.height) > blobAreaTh)
      {
        println("area is:"+(b.w*kinect.width)*(b.h*kinect.height));
        ++retVal;
      }
    }
  }
  println("-------");
  return retVal;
}

void drawBlobsAndEdges(boolean drawBlobs, boolean drawEdges)
{
  noFill();
  Blob b;
  EdgeVertex eA, eB;
  for (int n=0 ; n<theBlobDetection.getBlobNb() ; n++)
  {
    b=theBlobDetection.getBlob(n);
    if (b!=null)
    {
      // Edges
      if (drawEdges)
      {
        strokeWeight(2);
        stroke(0, 255, 0);
        for (int m=0;m<b.getEdgeNb();m++)
        {
          eA = b.getEdgeVertexA(m);
          eB = b.getEdgeVertexB(m);
          if (eA !=null && eB !=null)
            line(
            eA.x*width, eA.y*height, 
            eB.x*width, eB.y*height
              );
        }
      }

      // Blobs
      if (drawBlobs)
      {
        strokeWeight(1);
        stroke(255, 0, 0);
        rect(
        b.xMin*width, b.yMin*height, 
        b.w*width, b.h*height
          );
      }
    }
  }
}