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
import java.util.HashMap;

String emailDirectory = "emails/cuilla-m";

//ArrayList<Sample> train;
//ArrayList<Sample> test;

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

  allAddresses = new ArrayList<String>();

  if (buildBags) {
    TextProgressBar progress = new TextProgressBar("Building BAG of WORDS", files.size());

    for (Iterator iter = files.iterator(); iter.hasNext();) {
      progress.increment();
      java.io.File file = (java.io.File)iter.next();
      Email email = new Email(join(loadStrings(file.getPath()), "\n"));
      allAddresses.addAll(addressesFromEmail(email));
    }
    removeDuplicates(allAddresses);
  }

  if (saveBags) {
    println("save Bags of Words as csv files");
    String[] addressesCSV = allAddresses.toArray(new String[allAddresses.size()]);
    saveStrings(dataPath("bow/addresses.csv"), addressesCSV);
  }
  println("\nLoad labels.\n");
  HashMap<String, Integer> labelsForFiles = new HashMap<String, Integer>();
  String[] labels = loadStrings("labels.csv");
  for (int i = 0; i < labels.length; i++) {
    String[] parts = split(labels[i], ",");
    labelsForFiles.put(parts[1], int(parts[0]));
  }

  TextProgressBar progress = new TextProgressBar("Build samples", files.size());
  Sample[] trainingSamples = new Sample[files.size()];
  int i = 0;

  for (Iterator iter = files.iterator(); iter.hasNext();) {
    java.io.File file = (java.io.File)iter.next();

    Email email = new Email(join(loadStrings(file.getPath()), "\n"));
//    print(file.getPath() + " > ");
    int label = labelsForFiles.get(file.getPath());
//    println(label);
    
    trainingSamples[i] = new Sample(featureVectorFromEmail(email), label);
    i++;
    
    progress.increment();
  }

  OpenCV opencv = new OpenCV(this, 0, 0);


  HashMap<String, Float> averages = crossfold(3, trainingSamples);

  println();
  println("===Average Results===");
  println("Accuracy: " + averages.get("accuracy"));
  println("Precision: " + averages.get("precision"));
  println("Recall: " + averages.get("recall"));
  println("F-measure: " + averages.get("fmeasure"));



  //  textFont(loadFont("Helvetica-24.vlw"), 24);
}


HashMap crossfold(int nFolds, Sample[] samples) {
  HashMap<String, Float> result = new HashMap<String, Float>();
  result.put("accuracy", 0.0);
  result.put("precision", 0.0);
  result.put("recall", 0.0);
  result.put("fmeasure", 0.0);

  ArrayList<ArrayList<Sample>> folds = new ArrayList<ArrayList<Sample>>();
  for (int i = 0; i < nFolds; i++) {
    folds.add(new ArrayList<Sample>());
  }

  for (int i = 0; i < samples.length; i++) {
    int fold = (int)random(0, nFolds);

    folds.get(fold).add(samples[i]);
  }

  for (int i = 0; i < folds.size(); i++) {
    ArrayList<Sample> testing = folds.get(i);
    ArrayList<Sample> training = new ArrayList<Sample>();

    for (int j = 0; j < folds.size(); j++) {
      if (j != i) {
        training.addAll(folds.get(j));
      }
    }

    println();
    println("Executing fold " + (i+1) + "...");
    ClassificationResult score = executeFold(training, testing);

    println("training size: " + training.size() + " testing size: " + testing.size());
    result.put("accuracy", result.get("accuracy") + score.getAccuracy());
    result.put("precision", result.get("precision") + score.getPrecision());
    result.put("recall", result.get("recall") + score.getRecall());
    result.put("fmeasure", result.get("fmeasure") + score.getFMeasure());
  }

  result.put("accuracy", result.get("accuracy")/nFolds);
  result.put("precision", result.get("precision")/nFolds);
  result.put("recall", result.get("recall")/nFolds);
  result.put("fmeasure", result.get("fmeasure")/nFolds);

  return result;
}

ClassificationResult executeFold(ArrayList<Sample> training, ArrayList<Sample> testing) {

  ClassificationResult score = new ClassificationResult();

  classifier = new RandomForest(this);
  classifier.addTrainingSamples(training);
  classifier.train();

  for (Sample sample : testing) {
    double prediction = classifier.predict(sample);
    score.addResult((int)prediction == 1, (int)prediction == sample.label);
  }

  println("Accuracy: "+ score.getAccuracy() +" Precision: " + score.getPrecision() + " Recall: " + score.getRecall() + " F-measure: " + score.getFMeasure());

  return score;
}

void draw() {
}

