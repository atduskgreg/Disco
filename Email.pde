import javax.mail.*;
import java.util.Properties;
import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.util.Enumeration;
import java.util.Date;

class Email {
  MimeMessage parsedMessage;

  Email(String rawText) {
    Session s = Session.getDefaultInstance(new Properties());
    InputStream is = new ByteArrayInputStream(rawText.getBytes());

    try {
      parsedMessage = new MimeMessage(s, is);
    } 
    catch(Exception e) {
      println("failed to load message");
    }
  }

  String getBody() throws MessagingException, IOException {
    return (String)parsedMessage.getContent();
  }

  String getSubject() throws MessagingException, IOException {
    return parsedMessage.getSubject();
  }

  String getFrom() throws MessagingException, IOException {
    return ((InternetAddress)parsedMessage.getFrom()[0]).getAddress();
  }

  Date getDate() throws MessagingException, IOException {
    return parsedMessage.getSentDate();
  }

  String[] getRecipients() throws MessagingException, IOException {
    parsedMessage.getAllRecipients();
    Address[] addresses = parsedMessage.getAllRecipients();
    // If we don't find any, look in the X-To header as well
    if (addresses == null) {
      return parsedMessage.getHeader("X-To");
    } 
    else {
      String[] result = new String[addresses.length];
      for (int i = 0; i < addresses.length; i++) {
        result[i] = ((InternetAddress)addresses[i]).getAddress();
      }

      return result;
    }
  }

  MimeMessage parsedMessage() {
    return parsedMessage;
  }
}

