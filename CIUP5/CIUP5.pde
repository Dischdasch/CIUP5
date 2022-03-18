import java.util.Date; //<>//
import java.text.SimpleDateFormat;
import java.text.ParseException;
import java.time.LocalDate;
import java.text.DateFormat;
import java.util.Calendar;
import controlP5.*;

ControlP5 cp5;
PGraphics lienzo;
PImage img;
PImage pause;

float minlat, minlon, maxlat, maxlon;

float[] lats, lons;
String[] nombres, start, end;
Date[]  startTime, endTime;
int nest = 0;
int nrent = 0;
int r = 10;

int activeRoutes = 0;

float zoom;
//int px,py;
int x;
int y;

Table Estaciones;
Table Sitycleta;

PFont myFont;

float p1x, p2x;
float p1y, p2y;

int offsetx = 0;
int offsety = 140;

int day = 0;
int hour = 0;
Date DateBeginning;
Date DateEnding;

boolean stopped = false;

int sliderval = 0;
void setup() {
  size(1000, 1000, P3D);
  background(240);
  cp5 = new ControlP5(this);
    pause = loadImage("pause.jpg");
    pause.resize(40,40);
  addSliders();
  addToggle();
   myFont = createFont("Laksaman Bold", 100, true);
    textFont(myFont);
  //Cargamos información de estaciones de préstamo
  Estaciones = loadTable("Geolocalización estaciones sitycleta.csv", "header");
  //Estaciones.getRowCount() contiene el número de entradas
  //Creamos estruatura paar almacenar lo que nos interesa
  lats = new float[Estaciones.getRowCount()];
  lons = new float[Estaciones.getRowCount()];
  nombres = new String[Estaciones.getRowCount()];
  //Almacenamos datos en nuestra estructura
  nest = 0;
  for (TableRow est : Estaciones.rows()) {
    nombres[nest] = est.getString("nombre");
    lats[nest] = float(est.getString("latitud"));
    lons[nest] = float(est.getString("altitud"));
    nest++;
  }
  //Cargamos información de estaciones de préstamo
  Sitycleta = loadTable("SITYCLETA-2021.csv", "header");
  //Estaciones.getRowCount() contiene el número de entradas
  //Creamos estruatura paar almacenar lo que nos interesa
  start = new String[Sitycleta.getRowCount()];
  end = new String[Sitycleta.getRowCount()];
  startTime = new Date[Sitycleta.getRowCount()];
  endTime = new Date[Sitycleta.getRowCount()];
  //Almacenamos datos en nuestra estructura
  nrent = 0;
  for (TableRow rent : Sitycleta.rows()) {
    if (nrent == 0) {
    }
    start[nrent] = rent.getString("Rental place");
    end[nrent] = rent.getString("Return place");
    try {
      Date startDate = new SimpleDateFormat("dd-MM-yyyy HH:mm").parse(rent.getString("Start"));
      Date endDate = new SimpleDateFormat("dd-MM-yyyy HH:mm").parse(rent.getString("End"));
      startTime[nrent] = startDate;
      endTime[nrent] = endDate;
    }
    catch (ParseException e) {
      e.printStackTrace();
      System.out.print("you get the ParseException");
    }
    nrent++;
  }
  //Imagen del Mapa
  img=loadImage("map2.png");
  //Creamos lienzo par el mapa
  lienzo = createGraphics(img.width+105, img.height);
  lienzo.beginDraw();
  lienzo.background(50);
  lienzo.endDraw();

  //Latitud y longitud de los extremos del mapa de la imagen
  minlon = -15.4579;
  maxlon = -15.4051;
  minlat = 28.0711;
  maxlat = 28.1528;

  //Inicializa desplazamiento y zoom
  x = 0;
  y = 0;
  zoom = 1;

  //Compone imagen con estaciones sobre el lienzo
  dibujaMapayEstaciones();
}

void draw() {
  if(!stopped){
  try {
    Date DateBeginning = new SimpleDateFormat("dd-MM-yyyy HH:mm").parse("1-1-2021 00:00");
    Date DateEnding = new SimpleDateFormat("dd-MM-yyyy HH:mm").parse("1-1-2021 01:00");
    if (frameCount % 60 == 0)
    {
      background(50);
      //Centro de la imagen en el origen
      translate(0, 140);
      //Compone imagen con estaciones sobre el lienzo
      image(lienzo, 0, 0);
      DateFormat dateFormat = new SimpleDateFormat("dd-MM-yyyy HH");
      String strDate = dateFormat.format(addDays(addHours(DateBeginning, hour), day));
      textSize(55);
      text("Las Palmas, 2021", 510, 60);
      textSize(50);
      text("Sitycleta Usage", 510, 130);
      textSize(40);
      text("Date and Time:", 510, 300);
      text(strDate + " O'Clock", 510, 350);
      text("Choose a Date Here:",510, 775);
      DateBeginning = addHours(DateBeginning, hour);
      DateEnding = addHours(DateEnding, hour);
      connect(addDays(DateBeginning, day), addDays(DateEnding, day));
      cp5.getController("daySlider").setBroadcast(false);
      cp5.getController("daySlider").setValue(day);
      cp5.getController("daySlider").setBroadcast(true);
      hour +=1;
      if (hour >= 24) {
        hour = 0;
        day +=1;
        if (day >= 243) {
          day = 0;
        }
      }
      text("Sitycletas in Use:",510, 550);
      text(activeRoutes, 510, 600);
    }
  }
  catch(ParseException e) {
  }
  dibujaMapayEstaciones();
  }
}

void dibujaMapayEstaciones() {
  //Dibuja sobre el lienzo
  lienzo.beginDraw();
  lienzo.background(50);
  lienzo.image(img, 0, 0, img.width, img.height);
  //Círculo y etiqueta de cada estación según latitud y longitud
  for (int i=0; i<nest; i++) {
    float mlon = map(lons[i], minlon, maxlon, 0, img.width);
    //latitud invertida con respecto al eje y de la ventana
    float mlat = map(lats[i], maxlat, minlat, 0, img.height);
    lienzo.fill(255, 255, 255);
    lienzo.ellipse(mlon, mlat, r, r);
    //show names on hover
    if (mouseX >mlon-r/2+offsetx && mouseX < mlon+r/2+offsetx && mouseY > mlat-r/2+offsety && mouseY <mlat+r/2+offsety)
    {
      lienzo.fill(0, 0, 0);
      lienzo.textSize(20);
      lienzo.text(nombres[i], mlon+r, mlat);
    }
  }
  lienzo.endDraw();
}

void connect(Date beginDate, Date endDate)
{
  activeRoutes = 0;
  for (int rental = 0; rental < start.length; rental++) {
    if ((!beginDate.after(startTime[rental]) && !endDate.before(startTime[rental])) || (!beginDate.after(endTime[rental]) && !endDate.before(endTime[rental])))
    {
      activeRoutes +=1;
      for (int rentloc = 0; rentloc < nombres.length; rentloc++)
      {
        if (start[rental].equals(nombres[rentloc]))
        {
          p1x = map(lons[rentloc], minlon, maxlon, 0, img.width);
          p1y = map(lats[rentloc], maxlat, minlat, 0, img.height);
        }
      }
      for (int rentloc = 0; rentloc < nombres.length; rentloc++)
      {
        if (end[rental].equals(nombres[rentloc]))
        {
          p2x = map(lons[rentloc], minlon, maxlon, 0, img.width);
          p2y = map(lats[rentloc], maxlat, minlat, 0, img.height);
        }
      }
      strokeWeight(2);
      stroke(random(255), random(200), random(200));
      line(p1x, p1y, p2x, p2y);
    }
  }
}
public Date addDays(Date date, int days)
{
  Calendar cal = Calendar.getInstance();
  cal.setTime(date);
  cal.add(Calendar.DATE, days); //minus number would decrement the days
  return cal.getTime();
}

public Date addHours(Date date, int hours)
{
  Calendar cal = Calendar.getInstance();
  cal.setTime(date);
  cal.add(Calendar.HOUR_OF_DAY, hours); //minus number would decrement the days
  return cal.getTime();
}

public Date convertToDateViaSqlDate(LocalDate dateToConvert) {
  return java.sql.Date.valueOf(dateToConvert);
}
public LocalDate convertToLocalDateViaSqlDate(Date dateToConvert) {
  return new java.sql.Date(dateToConvert.getTime()).toLocalDate();
}
void addToggle(){
  cp5.addToggle("stopped")
     .setValue(false)
     .setPosition(955,950)
     .setImage(pause)
     .updateSize()
     ;
}
void addSliders() {
  cp5.addSlider("daySlider")
    .setBroadcast(false)
    .setPosition(500, 950)
    .setSize(450, 40)
    .setRange(0, 242)
    .setValue(day)
    .setLabel("");
    //.setBroadcast(true);
    ;
}
void daySlider(float val) {
  if (val != sliderval)
  {
  day = int(val);
  stopped = false;
  }
  sliderval = int(val);
}

  
