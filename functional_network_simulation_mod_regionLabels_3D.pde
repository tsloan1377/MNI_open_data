////////////////////////////////////////////
// A processing script to visualize functional networks of human MRI data according to the MIST parcellation 
// method described by Urchs et al 2017 
///////////////////////////////////////////

import peasy.*;
PeasyCam cam;
// Variables that influence the appearance
int[] resolutions = {7, 12, 20, 36, 64, 122, 197, 325, 444}; // Also th headers for the sorted hierarchy file.
float sizeScale = 10;
float spreadScale = 4.5;
float colorVariance = 30;
float baseColorVariance = 10;
int framesPerRegion =int(2.5*60);
int tChangeNetwork = 15*60;
int tEnd = 60*60*3; // 3 minutes.

 // Global variable declarations
int region;
int rel_ires;
float[][] coords;
int currN_relatives;
float red;
float green;
float blue;
int iCounter = 0;
int iAbs = 0;
int framesCount = 0;
int drawX;
int drawY;
int regionAlt = 1;
int rel_res; 
String filename;
String[] fileContents;
String[] tempArray;
String id_filename;
String[] id_fileContents;
String labelText;
int tLabels =4*60;
String[] hierarchy_file;
int[][] hierarchy;






public void setup(){
   size(1000,1000,P3D);
   cam = new PeasyCam(this, 400);
   //state = cam.getState();
   
   drawX = width/2;
   drawY = height/2 - 50;
   labelText = " "; 
   background(0);
   red = random(255);
   green = random(255);
   blue = random(255);
  
   //Without Peasycam Camera initial settings
   float fov = PI/3;
   float cameraZ = (height/2.0) / tan(fov/2.0);
   perspective(fov, float(width)/float(height), cameraZ/10.0, cameraZ*10.0);
  
  
  
   //Start in random region and resolution
   //region = int(random(444));
   //rel_ires = int(random(10));
   
   //Alternatively, start in the default mode network at lowest resolution
   region = 19;
   rel_ires = 0;
   
   smooth();
   //region=int(random(1,444));
   //rel_ires = int(random(7));
   rel_res = resolutions[rel_ires]; // Shouldn't include resolution 444
   filename = str(region) +"@MIST_444_rel_@MIST_" +str(rel_res);
   fileContents = loadStrings(filename +".csv");
  
   float[][] coords =  new float[fileContents.length][4];
   currN_relatives = fileContents.length;
   for (int i=0; i < fileContents.length; i++) {
      String[] tempArray = splitTokens(fileContents[i]);
      coords[i][0] = float(tempArray[0]);
      coords[i][1] = float(tempArray[1]);
      coords[i][2] = float(tempArray[2]);
      coords[i][3] = float(tempArray[3]);
      
  }
  
 
    // Have to initialize them here so they have a value.
   id_filename = str(int(random(444))) +"@MIST_444_rel_@MIST_" +str(resolutions[rel_ires]); // Alternatively, take a step to th lower resolution to find a cousin
   id_fileContents = loadStrings(id_filename +"_ids.txt");
   
    //if(id_fileContents.length > 0){
    //  region = int(id_fileContents[int(random(id_fileContents.length))]);
    //} else {
    //  rel_res = resolutions[1];
    //  id_filename = str(region) +"@MIST_444_rel_@MIST_" +str(rel_res); // Alternatively, take a step to th lower resolution to find a cousin
    //  id_fileContents = loadStrings(id_filename +"_ids.txt");
    //  region = int(id_fileContents[int(random(id_fileContents.length))]);
    //}
}





void draw(){
   iCounter++;
   iAbs++;
   framesCount++;
 
   // Alternate between networks occasionally by choosing a random region
   if(iCounter > tChangeNetwork){
    rel_ires = 1;
    rel_res = resolutions[rel_ires];
    region = int(random(444)); 
    iCounter = 0;
    framesCount = 0; // This resets them both to remove the quick flashes.
   }
   background(0);
   

     // Non-Peasy camera control
    float orbitRadius= mouseX*2;
    float ypos= sin(radians(frameCount/2))*orbitRadius;
    float xpos= cos(radians(frameCount/2))*orbitRadius;
    float zpos= mouseY*2;
    camera(xpos, ypos, zpos, width/2, height/2, 0, 0, 0, -1);
      
  
  
   
   
   
   
   
    

    // Load the hierarchy file
    hierarchy_file = loadStrings("sorted_hierarchy.csv");
     int[][] hierarchy =  new int[hierarchy_file.length][resolutions.length];
     for (int i=0; i < hierarchy_file.length; i++) {
        String[] tempArray = splitTokens(hierarchy_file[i], ",");
        hierarchy[i][0] = int(tempArray[0]);
        hierarchy[i][1] = int(tempArray[1]);
        hierarchy[i][2] = int(tempArray[2]);
        hierarchy[i][3] = int(tempArray[3]);
        hierarchy[i][4] = int(tempArray[4]);
        hierarchy[i][5] = int(tempArray[5]);
        hierarchy[i][6] = int(tempArray[6]);
        hierarchy[i][7] = int(tempArray[7]);      
        hierarchy[i][8] = int(tempArray[8]);         
    }

     // Load the coordinates for the current region and resolution
     region=constrain(region, 1,444);
     rel_res = resolutions[rel_ires]; // Shouldn't include resolution 444
     filename = str(region) +"@MIST_444_rel_@MIST_" +str(rel_res);
     fileContents = loadStrings(filename +".csv");
  
     float[][] coords =  new float[fileContents.length][4];
     currN_relatives = fileContents.length;
     for (int i=0; i < fileContents.length; i++) {
        String[] tempArray = splitTokens(fileContents[i]);
        coords[i][0] = float(tempArray[0]);
        coords[i][1] = float(tempArray[1]);
        coords[i][2] = float(tempArray[2]);
        coords[i][3] = float(tempArray[3]);
    }
      
      // Change the ROI after a certain number of frames.
      if(framesCount > framesPerRegion && iAbs > tLabels){

         // Biased random walk to push between lower and higher resolutions in a cyclic manner.       
         float SNR = sin(float(iAbs)/5)+0.75; // Heavy bias term to avoid lower resolutions - to explore  more the subnetworks.
         //println(SNR);
         // Sample a random gaussian function with a mean of SNR
         float sample = randomGaussian();
         
         if(sample + SNR > 0){
             rel_ires++;   // Higher resolution
         } else if (sample + SNR < 0){
            rel_ires--;    // Lower resolution
         }
         rel_ires = constrain(rel_ires,0,7); // This makes sure that we never try to open a resolution 444 file (don't exist)
         rel_res = resolutions[rel_ires];
         
        // Load the file containing the relatives at this resolution
        id_filename = str(region) +"@MIST_444_rel_@MIST_" +str(rel_res); 
        String[] id_fileContents = loadStrings(id_filename +"_ids.txt");
        framesCount = 0; // Reset the counter
        if(id_fileContents.length > 0){
          region = int(id_fileContents[int(random(id_fileContents.length))]);
          region=constrain(region, 1,444);
        } else {
          rel_res = resolutions[1];
          id_filename = str(region) +"@MIST_444_rel_@MIST_" +str(rel_res); 
          id_fileContents = loadStrings(id_filename +"_ids.txt");
          region = int(id_fileContents[int(random(id_fileContents.length))]);
          region=constrain(region, 1,444);
        }
      
      }   
       
  
   // Drift the base random colors
   red = red + randomGaussian() * baseColorVariance;
   green = green + randomGaussian() * baseColorVariance;
   blue = blue + randomGaussian() * baseColorVariance;
   red = constrain(red, 0, 255);
   green = constrain(green, 0, 255);
   blue = constrain(blue, 0, 255);

  
   fill(red, green, blue, 255); // Text color
   if(iAbs < tLabels){ // Only draw the Anterior/Posterior labels and credits for a few seconds..
     textSize(30);
     textAlign(CENTER);
     text("Anterior",drawX, 70);
     text("Posterior",drawX, height - 70);
     
     //Credits
     textSize(22);
     textAlign(RIGHT);
     text("Data credit: Urchs et al. 2017", width - 30, height - 100);
     text("MNI Open Research", width - 30, height - 75);
     text("Visualization by: Tyler Sloan", width - 30, height - 50);
     text("@ Quorumetrix", width - 30, height - 25); 
     
   } else { // Draw the region label, depending on the resolution.
        // Also include the official nomenclature for the region.
        textAlign(CENTER);
        textSize(16);
        String currText = "Region: " + str(region) + "@MIST_444 with relatives at resolution: MIST_" +str(rel_res);
        text(currText, width/2, height-30);   
       
       if(rel_ires < 6){ // As labels only included upto resolution 122
         // Open the file containing labels at the appropriate resolution.
         textSize(36);
         String label_filename = "MIST_" +str(resolutions[rel_ires]) ;
         fileContents = loadStrings(label_filename +".csv");
         
         String[][] labels =  new String[fileContents.length][3];
         for (int i=0; i < fileContents.length; i++) {
            String[] tempArray = splitTokens(fileContents[i], ";");
            labels[i][0] = tempArray[0];
            labels[i][1] = tempArray[1];
            labels[i][2] = tempArray[2];
        }
        // Find the appropriate region at the current resolution an draw it on screen
        int currInd =  hierarchy[int(region - 1)][rel_ires];
        String currLabel = labels[currInd][2];
        text(currLabel, drawX, height - 70);
        

      }
   }
   
   float colorVariance = 50;
   for(int n=0;n < currN_relatives; n++){
       for(int m=0;m < currN_relatives; m++){
        
         float prob = map(currN_relatives,2,50,20,1);
         prob = constrain(prob, 1, 100);
         float thisRand = random(100);
         if(thisRand > (100 - prob)){
           // An unelegant way to be sure they get the same color and opacity.      
           float rand_1 = randomGaussian() * colorVariance;
           float rand_2 = randomGaussian() * colorVariance;
           float rand_3 = randomGaussian() * colorVariance;
           float rand_4 = random(10/float(currN_relatives)*255); // Opacity
           rand_4 = constrain(rand_4, 50, 255);
           float rand_5 = randomGaussian()*2+ 1;//random(5);
           rand_5 = constrain(rand_5,1,5);
           strokeWeight(rand_5);
           //strokeWeight(2);
           stroke(red + rand_1, green + rand_2, blue + rand_3, rand_4);
           noFill();
           //float bezierVariance = 50;
           float bezierVariance = (sin(float(framesCount) / float(framesPerRegion*4)) * 50) + 20;
           
           //println(bezierVariance);
           float xi = width/2 + coords[n][0]*spreadScale;
           float yi = height/2 + coords[n][1]*spreadScale;
           float zi = coords[n][2]*spreadScale;
           float xf = width/2 + coords[m][0]*spreadScale;
           float yf = height/2 + coords[m][1]*spreadScale;
           float zf = coords[n][2]*spreadScale;
           float x_ctl1 = (xi + xf)/2 + randomGaussian()*bezierVariance;
           float y_ctl1 = (yi + yf)/2 + randomGaussian()*bezierVariance;
           float z_ctl1 = (zi + zf)/2 + randomGaussian()*bezierVariance;
           float x_ctl2 = (xi + xf)/2 + randomGaussian()*bezierVariance;
           float y_ctl2 = (yi + yf)/2 + randomGaussian()*bezierVariance;
           float z_ctl2 = (zi + zf)/2 + randomGaussian()*bezierVariance;
           
           if(((xi < drawX)&&(xf > drawX))||((xi > drawX)&&(xf < drawX))){ // If the connection crosses the midline, constrain it to pass through the center.
              float newRand = + randomGaussian()*bezierVariance;//randomGaussian() * height/50;
              bezier(xi, yi,zi,drawX,drawY+newRand,0,drawX,drawY+ newRand,0,xf, yf, zf); // Needs to be updated
              //bezier(xi, yi,drawX,drawY+newRand ,drawX,drawY+ newRand,xf, yf);

           } else {
              bezier(xi, yi,zi,x_ctl1,y_ctl1,z_ctl1,x_ctl2,y_ctl2,z_ctl1,xf, yf, zf);           }
           // Draw circles on each end of bezier curve.
           fill(red + rand_1, green + rand_2, blue + rand_3, rand_4 * 2);
           float circleSize = rand_5 * 2.5;
           noStroke();
           //ellipse(xi, yi,circleSize,circleSize);// coords[n][3] / sizeScale,coords[n][3] / sizeScale);
           //ellipse(xf, yf,circleSize,circleSize);// coords[m][3] / sizeScale, coords[m][3] / sizeScale);
           
           // Try using spheres instead of ellipses

            // first sphere 
            pushMatrix();
            translate(xi, yi, zi);
            sphere(circleSize);
            popMatrix();
            //second sphere
            pushMatrix();
            translate(xf, yf, zf);
            sphere(circleSize);
            popMatrix();                    
           
         }
        }

 }

  //delay(50);
  if(iAbs <= tEnd){
    // Save frame
    //saveFrame("frames/####.png");
    //println(frameCount/60.0 + " s");
  } else {
    noLoop();  
  }
}





//CameraState state;

//public void keyReleased() {
//  if (key == '1') state = cam.getState();
//  if (key == '2') cam.setState(state, 1000);
//}