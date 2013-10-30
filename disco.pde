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
import org.apache.commons.io.filefilter.*;

//import org.apache.commons.io.filefilter.RegexFileFilter;

//import edu.stanford.nlp.ling.CoreLabel;
//import edu.stanford.nlp.ling.HasWord;
//import edu.stanford.nlp.process.CoreLabelTokenFactory;
//import edu.stanford.nlp.process.DocumentPreprocessor;
//import edu.stanford.nlp.process.PTBTokenizer;
//import edu.stanford.nlp.util.CoreMap;

import java.util.Properties;
import java.util.List;

String emailDirectory = "emails/cuilla-m";

boolean buildBags = true;
boolean saveBags = true;

ArrayList<String> allAddresses;
ArrayList<String> allEntities;

RandomForest classifier;
//StanfordCoreNLP pipeline;

float[] featureVectorFromEmail(Email email, File file) {
  float[] result = new float[allAddresses.size() + allEntities.size() + 1]; // vector size is number of email addresses plus number of entities plus one for the scaled-date
  try {
    ArrayList<String> emailAddresses = new ArrayList<String>();
    emailAddresses.add(email.getFrom());
    emailAddresses.addAll(Arrays.asList(email.getRecipients()));
    float[] addressBow = addressBow(emailAddresses);
    float scaledDate = scaledDate(email.getDate());
    float[] entitiesBow = entityBow(entitiesFromEmail(email, file));
    System.arraycopy(addressBow, 0, result, 0, addressBow.length);
    System.arraycopy(entitiesBow, addressBow.length, result, 0, entitiesBow.length);

    result[result.length-1] = scaledDate;
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

float[] entityBow(ArrayList<String> emailEntities) {
  float[] result = new float[allEntities.size()];

  for (int i = 0; i < allEntities.size(); i++) {
    if (emailEntities.indexOf(allAddresses.get(i)) >= 0) {
      result[i] = 1.0;
    } 
    else {
      result[i] = 0.0;
    }
  }

  return result;
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

ArrayList<String> entitiesFromEmail(Email email, File emailFile) {
  ArrayList<String> result = new ArrayList<String>();
  // read them from the csv
  String entitiesCsv = emailFile.getParent() + "/entities/" + emailFile.getName() + "csv";
  String[] lines = loadStrings(entitiesCsv);
  for(int i = 0; i < lines.length; i++){
    String[] parts = split(lines[i], ",");
    result.add(parts[0]);  
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
  RegexFileFilter fileFilter = new RegexFileFilter("(.+)\\.$");
  Collection<File> files = FileUtils.listFiles(new java.io.File(dataPath(emailDirectory)), fileFilter, DirectoryFileFilter.DIRECTORY);
  println(files.size() + " emails found.");

  //  println("Setup CoreNLP.");
  //  Properties props = new Properties();
  //  props.put("annotators", "tokenize, ssplit, pos, lemma, parse, ner, dcoref"); // , dcoref
  //  pipeline = new StanfordCoreNLP(props);

  allAddresses = new ArrayList<String>();
  allEntities = new ArrayList<String>();

  if (buildBags) {
    TextProgressBar progress = new TextProgressBar("Building BAG of WORDS", files.size());

    for (Iterator iter = files.iterator(); iter.hasNext();) {
      progress.increment();
      java.io.File file = (java.io.File)iter.next();
      Email email = new Email(join(loadStrings(file.getPath()), "\n"));
      allAddresses.addAll(addressesFromEmail(email));
      allEntities.addAll(entitiesFromEmail(email, file));
    }
    removeDuplicates(allAddresses);
    print("Num Entities before de-dup: " + allEntities.size());
    removeDuplicates(allEntities);
    println(" and after: " + allEntities.size());
  }

  if (saveBags) {
    println("save Bags of Words as csv files");
    String[] addressesCSV = allAddresses.toArray(new String[allAddresses.size()]);
    saveStrings(dataPath("bow/addresses.csv"), addressesCSV);

    String[] entitiesCSV = allEntities.toArray(new String[allEntities.size()]);
    saveStrings(dataPath("bow/entities.csv"), entitiesCSV);
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
    int label = labelsForFiles.get(file.getPath());

    trainingSamples[i] = new Sample(featureVectorFromEmail(email, file), label);
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
    if (prediction == 1) {
      println("WE PREDICTED AN EMAIL!");
    }
    score.addResult((int)prediction == 1, (int)prediction == sample.label);
  }

  println("Accuracy: "+ score.getAccuracy() +" Precision: " + score.getPrecision() + " Recall: " + score.getRecall() + " F-measure: " + score.getFMeasure());

  return score;
}

void draw() {
}

