import codeanticode.gsvideo.*;
import monclubelec.javacvPro.*;

PImage img;

Blob[] blobsArray=null;
GSCapture cam;
OpenCV opencv;

int fpsCapture=10; // framerate de Capture

int millis0=0; // variable mémorisation millis()

void setup() { // fonction d'initialisation exécutée 1 fois au démarrage
  size (800, 600);
  frameRate(fpsCapture);
  cam = new GSCapture(this, width, height);
  opencv = new OpenCV(this); // initialise objet OpenCV à partir du parent This
  opencv.allocate(width, height); // initialise les buffers OpenCv à la taille de l'image
  cam.start();  // démarre objet GSCapture = la webcam 
}


void  draw() { // fonction exécutée en boucle
  int x, y, xp, yp;

  background(255);
  if (cam.available() == true) { // si une nouvelle frame est disponible sur la webcam
    cam.read(); // acquisition d'un frame 
    opencv.copy(cam.get()); // autre possibilité - charge directement l'image GSVideo dans le buffer openCV
    opencv.flip("HORIZONTAL");
    opencv.threshold(0.5, "BINARY"); // seuillage binaire pour éliminer le fond 
    blobsArray = opencv.blobs(opencv.area()/64, opencv.area()/2, 1, false, 1000, false ); // blobs javacvPro +/- debug    
    if (blobsArray.length > 0) {
      xp = blobsArray[0].rectangle.width/2;
      yp = blobsArray[0].rectangle.height/2;
      x = blobsArray[0].centroid.x;
      y = blobsArray[0].centroid.y;
      stroke(0);
      rect(x-xp, y-yp, xp*2, yp*2);
    }
  }
}


