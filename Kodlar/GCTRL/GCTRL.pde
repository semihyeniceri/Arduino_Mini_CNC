import java.awt.event.KeyEvent;
import javax.swing.JOptionPane;
import processing.serial.*;

Serial port = null;

String portname = null;


boolean streaming = false;
float speed = 0.001;
String[] gcode;
int i = 0;

void openSerialPort()
{
  if (portname == null) return;
  if (port != null) port.stop();
  
  port = new Serial(this, portname, 9600);
  
  port.bufferUntil('\n');
}

void selectSerialPort()
{
  String result = (String) JOptionPane.showInputDialog(frame,
    "Arduino kartımızın bağlı olduğu portu seçiniz",
    "Port Seçiniz",
    JOptionPane.PLAIN_MESSAGE,
    null,
    Serial.list(),
    0);
    
  if (result != null) {
    portname = result;
    openSerialPort();
  }
}

void setup()
{
  size(500, 250);
  openSerialPort();
}

void draw()
{
  background(0);  
  fill(255);
  int y = 24, dy = 12;
  text("INSTRUCTIONS", 12, y); y += dy;
  text("p: Port Seçin", 12, y); y += dy;
  text("Yön Tuşları: x-y eksen hareketi", 12, y); y += dy;
  text("5 & 2: z eksen hareketi", 12, y); y += dy;
  text("$: Ekran ayarları", 12, y); y+= dy;
  text("h: Başlangıca Git", 12, y); y += dy;
  text("0: Ayarlar Sıfırlanıyor", 12, y); y += dy;
  text("g: g-code Dosyası", 12, y); y += dy;
  text("x: CNC'yi durdurur", 12, y); y += dy;
  y = height - dy;
  text("İşlem hızı: " + speed + " inches per step", 12, y); y -= dy;
  text("Bağlantı portu: " + portname, 12, y); y -= dy;
}

void keyPressed()
{
  if (key == '1') speed = 0.001;
  if (key == '2') speed = 0.01;
  if (key == '3') speed = 0.1;
  
  if (!streaming) {
    if (keyCode == LEFT) port.write("G21/G90/G1 X-10  F3500\n");
    if (keyCode == RIGHT) port.write("G21/G90/G1 X10 F3500\n");
    if (keyCode == UP) port.write("G21/G90/G1 Y10 F3500\n");
    if (keyCode == DOWN) port.write("G21/G90/G1 Y-10 F3500\n");
    if (key == '5') port.write("M300 S50\n");
    if (key == '2') port.write("M300 S30\n");
    if (key == 'h') port.write("G90\nG20\nG00 X0.000 Y0.000 Z0.000\n");
    if (key == 'v') port.write("$0=75\n$1=74\n$2=75\n");
    //if (key == 'v') port.write("$0=100\n$1=74\n$2=75\n");
    if (key == 's') port.write("$3=10\n");
    if (key == 'e') port.write("$16=1\n");
    if (key == 'd') port.write("$16=0\n");
    if (key == '0') openSerialPort();
    if (key == 'p') selectSerialPort();
    if (key == '$') port.write("$$\n");
  }
  
  if (!streaming && key == 'g') {
    gcode = null; i = 0;
    File file = null; 
    println("Dosya Yükleniyor...");
    selectInput("Bir dosya seçin", "Seçilen dosya", file);
  }
  
  if (key == 'x') streaming = false;
}

void fileSelected(File selection) {
  if (selection == null) {
    println("iptal işlemi gerçekleştirildi");
  } else {
    println("Kullanıcı seçimi " + selection.getAbsolutePath());
    gcode = loadStrings(selection.getAbsolutePath());
    if (gcode == null) return;
    streaming = true;
    stream();
  }
}

void stream()
{
  if (!streaming) return;
  
  while (true) {
    if (i == gcode.length) {
      streaming = false;
      return;
    }
    
    if (gcode[i].trim().length() == 0) i++;
    else break;
  }
  
  println(gcode[i]);
  port.write(gcode[i] + '\n');
  i++;
}

void serialEvent(Serial p)
{
  String s = p.readStringUntil('\n');
  println(s.trim());
  
  if (s.trim().startsWith("ok")) stream();
  if (s.trim().startsWith("error")) stream(); 
}
