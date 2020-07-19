---
layout: post
title: "Build your own head tracker"
real_date: 2020-07-18T17:40:31-06:00
date: 2020-07-18T17:40:31-06:00
redirect_from:
  - /2020/07/20/build-your-own-head-tracker.html
---

My son has been playing a lot of the [DCS World](https://www.digitalcombatsimulator.com)
flight simulator lately, and started talking about building a head tracker. I
didn't even know this was a thing, outside of expensive Virtual Reality gear.
A head tracker is a relatively low cost device that allows you to control your
view in a game (look around the cockpit) just by moving your head - so you can
keep your hands focused on steering and throttle, etc. He had read about building
an infrared based tracker for $10 - but the parts needed didn't seem convenient
(PlayStation 3 camera and a floppy disk? - google it, you may like that solution better).
Since I have [experience with programming a Teensy]({{site.baseurl}}/2015/11/07/build-your-own-single-function-keyboard.html)),
I knew it was possible to create a relatively cheap device that could simulate a
game controller. After searching for "head tracker teensy" I came across this
[Inertial Head Tracker post](http://crispycircuits.blogspot.com/2018/06/inertial-head-tracker.html)
which had the exact same idea, and had already done most of the hard work for me.

However, some of the details on that post were a little unclear, and I had a lot
of trouble with the source code on that page - I have a feeling it was corrupted
somehow in the publishing process because some of it just doesn't make sense and
will not compile. I'm going to add my interpretation, and code, for what needs to be
done, but defer all credit for this idea to `cmarzano`, the author of that post.


## Parts

- [Teensy 3.2 w/pins](https://www.pjrc.com/store/teensy32.html) - you _might_ be
able to save some money by using the Teensy-LC - I have not tried it. Newer
versions of the Teensy should also work. I bought the [version with pins](https://www.pjrc.com/store/teensy32_pins.html) to save
me some soldering work.
- [Teensy Prop Shield w/Motion Sensors](https://www.pjrc.com/store/prop_shield.html) -
it should be obvious that you cannot use the low cost Prop Shield, since the motion
sensors are the part we need.
- A long micro-USB cable. Long enough to allow freedom to connect the device on your
head to your computer. I went with one of these 10ft cables (https://smile.amazon.com/gp/product/B07JBN6C5C).
- [Some header pins](https://smile.amazon.com/2-54mm-Breakaway-Female-Connector-Arduino/dp/B01MQ48T2V/) to make it easier to mount the Prop Shield on the Teensy.

- [Teensyduino IDE](https://www.pjrc.com/teensy/td_download.html) - used to compile and publish programs to your Teensy.
- NXPMotionSense library - this _may_ be included in the Examples packaged with your Arduino software. If not, go to


## Addendum to steps from the original source
- Open Teensy/Arduino - the first thing you should do is go to the Tools menu and choose your Board (Teensy 3.2 for me).
Now when you open the `File | Examples` menu, there should be a Teensy 3.2 section that includes NXPMotionSense.
> If you don't see the NXPMotionSense examples, you can download them from
the [NXPMotionSense github page](https://github.com/PaulStoffregen/NXPMotionSense), click on Code, and Download Zip. Extract the zip to a directory.
- Open the `CalibrateSensors` example sketch from the NXPMotionSense group. (`File | Examples | NXPMotionSense | CalibrateSensors`).
Or `File | Open` and find the sketch in the `examples` directory of the extracted zip.
- Click the Verify button (or `Sketch | Verify` menu)
to make sure it works. If it compiles, click the Upload button.
- _follow instructions from original post to calibrate using MotionCal_
- Open the `MahonyIMU` example sketch from the NXPMotionSense group (`File|Examples|NXPMotionSense|MahonyIMU`)
- Click the Verify button. If it works - great! But you will likely get a fatal error stating that it cannot find `MahonyAHRS.h`.
You need to install the MahonyAHRS library. As of this writing, the version (1.1) available in the Arduine Library Manager
does _not_ work. You need to install the latest unreleased copy from the source. Go to https://github.com/PaulStoffregen/MahonyAHRS,
click Code, Download Zip. Extract the zip to your Arduino libraries directory (which is likely `Arduino/libraries` in your user `Documents` directory).
With the library installed, you should be able to Verify the sketch successfully. (I did see some _warnings_ but they can be ignored).

## Code
- Instead of using the code from the original post, use mine below (or, if gets mangled
like it did on the original post, you can always [get the latest version from my Github](https://github.com/joshuaflanagan/head_tracker/blob/master/HeadtrackJoystick.ino).

{% highlight c %}
// Inertial Monitoring Unit (IMU) using Mahony filter.
//
// To view this data, use the Arduino Serial Monitor to watch the
// scrolling angles, or run the OrientationVisualiser example in Processing.

#include <NXPMotionSense.h>
#include <MahonyAHRS.h>
#include <Wire.h>
#include <EEPROM.h>

NXPMotionSense imu;
Mahony filter;

int joyheading;
int joypitch;
int joyroll;
float headingcenter = 180;
float headingoffset;
float adjustedheading;

void setup() {
  Serial.begin(9600);
  imu.begin();
  filter.begin(100); // 100 measurements per second

  //TODO: make this settable by pressing a button
  headingcenter=328;
  headingoffset = headingcenter - 180;
}

void loop() {
  float ax, ay, az;
  float gx, gy, gz;
  float mx, my, mz;
  float roll, pitch, heading;

  if (imu.available()) {
    // Read the motion sensors
    imu.readMotionSensor(ax, ay, az, gx, gy, gz, mx, my, mz);

    // Update the Mahony filter
    filter.update(gx, gy, gz, ax, ay, az, mx, my, mz);

    // print the heading, pitch and roll
    heading = filter.getYaw(); //  0..360
    pitch = filter.getPitch(); //  -90..90
    roll = filter.getRoll();   // -180..180
 
    Serial.print("Orientation: ");
    Serial.print(heading);
    Serial.print(" ");
    Serial.print(pitch);
    Serial.print(" ");
    Serial.println(roll);

    adjustedheading = heading - headingoffset;
    if (adjustedheading < 0){
      adjustedheading = adjustedheading + 360;
    }
    if (adjustedheading > 360){
      adjustedheading = adjustedheading - 360;
    }
    joyheading = (adjustedheading / 360) * 1023;
    joypitch = ((pitch + 90) / 180) * 1023;
    joyroll = ((roll + 180) / 360) * 1023;

    Joystick.X(joyheading);
    Joystick.Y(joypitch);
    Joystick.Z(joyroll);

    Serial.print("Joyvalue: ");
    Serial.print(joyheading);
    Serial.print(" ");
    Serial.print(joypitch);
    Serial.print(" ");
    Serial.println(joyroll);
  }
}
{% endhighlight %}
