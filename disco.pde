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
import java.util.HashSet;

ArrayList<String[]> train;
ArrayList<String[]> test;

boolean buildBags = true;
boolean saveBags = true;

ArrayList<String> allAddresses;


float percentTrain = 0.3;

String[] featureVectorFromEmail(Email email) {
  String[] result = new String[2];
  try {
    result[0] = email.getSubject();
    result[1] = email.getFrom();
  } 
  catch(Exception e) {
    println("error loading email: " + e.toString());
  }
  return result;
}

ArrayList<String> addressesFromEmail(Email email) {
  ArrayList<String> result = new ArrayList<String>();
  try {
    result.add( email.getFrom() );
    String[] recipients = email.getRecipients();
    for (int i = 0; i < recipients.length; i++) {
      result.add(recipients[i]);
    }
  } 
  catch(Exception e) {
    println("error loading email: " + e.toString());
  }

  return result;
}

void setup() {
  size(800, 800);
  Collection<File> files = FileUtils.listFiles(new java.io.File(dataPath("emails/cuilla-m")), FileFileFilter.FILE, DirectoryFileFilter.DIRECTORY);
  println(files.size() + " emails found.");

  train = new ArrayList<String[]>();
  test = new ArrayList<String[]>();

  allAddresses = new ArrayList<String>();

  if (buildBags) {
    int i = 0;
    for (Iterator iter = files.iterator(); iter.hasNext();) {
      println("Building BAG of WORDS: " + (i+1) + "/" +files.size());
      i++;
      java.io.File file = (java.io.File)iter.next();
      Email email = new Email(join(loadStrings(file.getPath()), "\n"));
      allAddresses.addAll(addressesFromEmail(email));
    }
  }
  
  if(saveBags){
    String[] addressesCSV = allAddresses.toArray(new String[allAddresses.size()]);
    saveStrings("bow/addresses.csv", addressesCSV);
  }

  for (Iterator iter = files.iterator(); iter.hasNext();) {
    java.io.File file = (java.io.File)iter.next();
    Email email = new Email(join(loadStrings(file.getPath()), "\n"));

    if (random(0, 1) < percentTrain) {
      train.add(featureVectorFromEmail(email));
    } 
    else {
      test.add(featureVectorFromEmail(email));
    }
  }

  println("Train: " + train.size() + " Test: " + test.size() + " percent: " + (float)train.size()/(test.size() + train.size()));

  removeDuplicates(allAddresses);
  println("num addresses found: " + allAddresses.size());


  //  textFont(loadFont("Helvetica-24.vlw"), 24);
}

void removeDuplicates(ArrayList<String> list) {
  HashSet hs = new HashSet();
  hs.addAll(list);
  list.clear();
  list.addAll(hs);
}

void draw() {
}

