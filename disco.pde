import org.apache.commons.io.FileUtils;
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
import java.util.Calendar;
import java.util.GregorianCalendar;

String emailDirectory = "emails/cuilla-m";

ArrayList<Sample> train;
ArrayList<Sample> test;

boolean buildBags = true;
boolean saveBags = true;

ArrayList<String> allAddresses;

float percentTrain = 0.3;

RandomForest classifier;

float[] featureVectorFromEmail(Email email) {
  float[] result = new float[allAddresses.size() + 1]; // vector size is number of email addresses plus one for the scaled-date
  try {
    ArrayList<String> emailAddresses = new ArrayList<String>();
    emailAddresses.add(email.getFrom());
    emailAddresses.addAll(Arrays.asList(email.getRecipients()));
    float[] addressBow = addressBow(emailAddresses);
    float scaledDate = scaledDate(email.getDate());
    System.arraycopy(addressBow, 0, result, 0, addressBow.length);
    result[addressBow.length] = scaledDate; 
  }
  catch(Exception e) {
    println("error loading email: " + e.toString());
  }
  return result;
}

float scaledDate(Date d) {
  GregorianCalendar startDate = new GregorianCalendar(1998, 1, 1);
  GregorianCalendar endDate = new GregorianCalendar(2004, 1, 1);

  long elapsedTime = d.getTime() - startDate.getTimeInMillis();
  long totalTime = endDate.getTimeInMillis() - startDate.getTimeInMillis();
    
  return ((float)elapsedTime/(float)totalTime);
}

float[] addressBow(ArrayList<String> emailAddresses) {
  float[] result = new float[allAddresses.size()];

  for (int i = 0; i < allAddresses.size(); i++) {
    if (emailAddresses.indexOf(allAddresses.get(i)) >= 0) {
      result[i] = 1.0;
    } 
    else {
      result[i] = 0.0;
    }
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

void removeDuplicates(ArrayList<String> list) {
  HashSet hs = new HashSet();
  hs.addAll(list);
  list.clear();
  list.addAll(hs);
}

void setup() {
  size(800, 800);
  Collection<File> files = FileUtils.listFiles(new java.io.File(dataPath(emailDirectory)), FileFileFilter.FILE, DirectoryFileFilter.DIRECTORY);
  println(files.size() + " emails found.");

  train = new ArrayList<Sample>();
  test = new ArrayList<Sample>();

  allAddresses = new ArrayList<String>();

  if (buildBags) {
    TextProgressBar progress = new TextProgressBar("Building BAG of WORDS", files.size());

    for (Iterator iter = files.iterator(); iter.hasNext();) {
      progress.increment();
      java.io.File file = (java.io.File)iter.next();
      Email email = new Email(join(loadStrings(file.getPath()), "\n"));
      allAddresses.addAll(addressesFromEmail(email));
    }
  }

  removeDuplicates(allAddresses);

  if (saveBags) {
    String[] addressesCSV = allAddresses.toArray(new String[allAddresses.size()]);

    saveStrings(dataPath("bow/addresses.csv"), addressesCSV);
  }
  
 
  for (Iterator iter = files.iterator(); iter.hasNext();) {
    java.io.File file = (java.io.File)iter.next();

    Email email = new Email(join(loadStrings(file.getPath()), "\n"));

    // FIXME: for now label all samples as 1
    if (random(0, 1) < percentTrain) {
      train.add(new Sample(featureVectorFromEmail(email), 1));
    } 
    else {
      test.add(new Sample(featureVectorFromEmail(email), 1));
    }
  }
  
  println("num addresses found: " + allAddresses.size());
  println("Train: " + train.size() + " Test: " + test.size() + " percent: " + (float)train.size()/(test.size() + train.size()));

  OpenCV opencv = new OpenCV(this,0,0);

  classifier = new RandomForest(this);
  classifier.addTrainingSamples(train);
  classifier.train();
  

  //  textFont(loadFont("Helvetica-24.vlw"), 24);
}

void draw() {
}

