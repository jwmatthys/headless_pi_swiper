import java.util.*;
import javax.mail.*;
import javax.mail.internet.*;
import javax.activation.*;
import netP5.*;
import oscP5.*;


boolean acceptSwipeFlag = false;
String defaultEvent = "Performance Lab";
//String defaultEmail = "lmclaugh@carrollu.edu";
String defaultEmail = "jmatthys@carrollu.edu";
String text = "";
String digits = "";
String dateStamp;
boolean code16 = false;
PrintWriter output, finalFile;
String filename;
final int debounce = 1000; // time in ms to retrigger
int pressedTime;
final int showIDtime = 3000; // ms
File temp;
String desktopPath;
boolean internetUp = false;
boolean internetLast = false;
boolean buttonPressed = false;
final int internetCheckTime = 30000; // ms
int lastInternetCheck;
OscP5 oscP5;
NetAddress myRemoteLocation;

Properties props;
Session session;

void setup()
{
  size(460, 300);
  //smooth();
  //background(0);
  oscP5 = new OscP5(this, 8001);
  myRemoteLocation = new NetAddress("127.0.0.1", 8000);
      OscMessage myMessage = new OscMessage("/message");
    myMessage.add("Stand by...");
    oscP5.send(myMessage, myRemoteLocation);
  try {
    temp = File.createTempFile("attendance_p5_", ".csv");
    desktopPath =System.getProperty("user.home") + "/Desktop/";
  }
  catch (Exception e)
  {
    e.printStackTrace();
    temp = new File("tempfile.csv");
  }
  dateStamp = nf(month(), 2)+"/"+nf(day(), 2)+"/"+nf(year(), 4);
  props = System.getProperties();
  props.put("mail.transport.protocol", "smtp");
  props.put("mail.smtp.host", "mail.gandi.net");
  props.put("mail.smtp.port", "587");
  props.put("mail.smtp.auth", "true");
  props.put("mail.smtp.starttsl.enable", "true");
  session = Session.getInstance(props, null);
  output = createWriter(temp);
  output.println("Date, Time, ID, Name");
  pressedTime = millis();
}

void draw()
{
  background(0);
  if (buttonPressed && millis() > pressedTime + debounce) 
  {
    println("saving...");
    OscMessage myMessage = new OscMessage("/name");
    myMessage.add("Saving & sending");
    oscP5.send(myMessage, myRemoteLocation);

    output.flush();
    output.close();
    // is this just too hacky???
    filename = desktopPath+"PerformanceLab_"+nf(month(), 2)+"_"+nf(day(), 2)+"_"+year()+".csv";
    saveStrings(filename, loadStrings(temp));
    println("sending...");
    String subject = "Performance Lab Attendance "+month()+"/"+day()+"/"+year();
    MimeMessage message = new MimeMessage(session);
    try {
      message.setFrom(new InternetAddress("performancelab@matthysmusic.com", "Attendance Swiper"));
      String outgoingAddress = defaultEmail;
      message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(outgoingAddress, false));

      message.setSubject(subject);
      MimeBodyPart mbp1 = new MimeBodyPart();
      mbp1.setText("Automatically generated report attached.\n\nJoel");
      MimeBodyPart mbp2 = new MimeBodyPart();
      mbp2.attachFile(filename);
      Multipart mp = new MimeMultipart();
      mp.addBodyPart(mbp1);
      mp.addBodyPart(mbp2);
      message.setContent(mp);
      SMTPTransport t = (SMTPTransport)session.getTransport("smtp");
      t.connect("mail.gandi.net", "performancelab@matthysmusic.com", "sUz8icS3ZpVrnL");
      t.sendMessage(message, message.getAllRecipients());
      println("sent!");
      OscMessage myMessage1 = new OscMessage("/name");
      myMessage.add("Success");
      oscP5.send(myMessage1, myRemoteLocation);
      // reload file (to add to it)
      String[] lines = loadStrings(temp);
      try {
        temp = File.createTempFile("attendance_p5_", ".csv");
      }
      catch (Exception e)
      {
        e.printStackTrace();
        temp = new File("tempfile.csv");
        OscMessage myMessage2 = new OscMessage("/message");
        myMessage.add("Error sending");
        oscP5.send(myMessage2, myRemoteLocation);
      }
      output = createWriter(temp);
      for (int i = 0; i < lines.length; i++) output.println(lines[i]);
    } 
    catch (Exception e)
    {
      e.printStackTrace();
    }

    pressedTime = millis();
    buttonPressed = false;
  }
  if (millis() > lastInternetCheck + internetCheckTime)
  {
    thread("checkConnection");
    lastInternetCheck = millis();
  }
}

void keyPressed()
{
  if (keyCode > 64 && digits.length() > 0 ) text += key;
  if ((keyCode == 32 || keyCode == 44) && text.length() > 0) text += " ";
  if (keyCode > 47 && keyCode < 58 && !code16)
  {
    digits += key;
  }
  if (keyCode == 10 || keyCode == 0)
  {
    String timeStamp = nf(hour(), 2)+":"+nf(minute(), 2);
    int carrollIDnumber = int(split(digits, "6298601")[0]);
    String name = text.trim();
    output.println(dateStamp+", "+timeStamp+", "+carrollIDnumber+", "+name);
    text = "";
    digits = "";
    OscMessage myMessage = new OscMessage("/name");
    myMessage.add(name);
    oscP5.send(myMessage, myRemoteLocation);
  }
  code16 = (keyCode == 16);
  //TODO: Turn on LED if successful
  if (keyCode == DOWN) buttonPressed = true;
  if (keyCode == ESC)
  {
    println("exiting...");
    output.flush();
    output.close();
    println("goodbye!");
    exit();
  }
}

void checkConnection()
{
  Process p = exec("ping", "-c", "1", "8.8.8.8");
  try {
    int result = p.waitFor();
    if (result == 0) internetUp = true;
    else internetUp = false;
  }
  catch (Exception e) {
    internetUp = false;
    e.printStackTrace();
  }
  if (internetUp != internetLast)
  {
    internetLast = internetUp;
    OscMessage myMessage = new OscMessage("/message");
    if (internetUp) myMessage.add("Connected");
    else myMessage.add("Disconnected");
    oscP5.send(myMessage, myRemoteLocation);
  }
}

void oscEvent(OscMessage theOscMessage)
{
  print("### received an osc message.");
  print(" addrpattern: "+theOscMessage.addrPattern());
  println(" typetag: "+theOscMessage.typetag());
  buttonPressed = true;
}
