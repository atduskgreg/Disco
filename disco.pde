import org.apache.commons.io.FileUtils;
import gab.opencv.*;
import gab.opencv.*;
import org.opencv.core.Core;
import org.opencv.core.CvType;
import org.opencv.core.Mat;
import org.opencv.core.Scalar;
import org.opencv.core.TermCriteria;
import java.util.Map;
import java.util.Arrays;
import java.util.TreeMap;
import java.util.Collection;
import java.util.Iterator;

ArrayList<String[]> train;
ArrayList<String[]> test;

float percentTrain = 0.3;

String[] featureVectorFromEmail(Email email){
  String[] result = new String[2];
  try{
  result[0] = email.getSubject();
  result[1] = email.getFrom();
  } catch(Exception e){
    println("error loading email: " + e.toString());
  }
  return result;
}

void setup() {
  size(800, 800);
  Collection<File> files = FileUtils.listFiles(new java.io.File(dataPath("cuilla-m")), FileFileFilter.FILE, DirectoryFileFilter.DIRECTORY);
  println(files.size() + " emails found.");

  train = new ArrayList<String[]>();
  test = new ArrayList<String[]>();

  for (Iterator iter = files.iterator(); iter.hasNext();) {
    java.io.File file = (java.io.File)iter.next();
    println(file.getPath());
    
    Email email = new Email(join(loadStrings(file.getPath()), "\n"));
    
    if(random(0,1) < percentTrain){
      train.add(featureVectorFromEmail(email));
    } else{
      test.add(featureVectorFromEmail(email));
    }
  }
  
  println("Train: " + train.size() + " Test: " + test.size() + " percent: " + (float)train.size()/(test.size() + train.size()));

  //  textFont(loadFont("Helvetica-24.vlw"), 24);
  //  String msg = join(loadStrings("message2.txt"), "\n");
  //  mail = new Email(msg);
  //  size(800, 800);
}

void draw() {
}

