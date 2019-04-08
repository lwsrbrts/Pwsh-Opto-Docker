# Pwsh-Opto-Docker

Docker container to run a PowerShell script which monitors a Raspberry Pi's GPIO pin (configurable) for an opto-coupler circuit triggered by an AC voltage PIR. Additionally sends notifications using Pushover if the PIR is triggered between 1am and 5am as these are unsociable hours.

An AC voltage PIR is connected to an octo-coupler circuit which is in turn connected to a GPIO pin on a Raspberry Pi. When the PIR is activated by movement, the octo-coupler causes the GPIO pin to go low. The specified GPIO pin is monitored every second. When the pin goes LOW (zero, false) the PoSHue module tells a `[HueGroup]` to turn on by recalling a specific scene. During certain hours (from twilight) to 23:00, a "bright" evening scene is triggered, providing ample light for normal evening activities. After 23:00, a "dimmed" night scene is triggered instead to avoid flooding light on to neighbours' properties.

Additionally, during 01:00 to 05:00 if motion is detected, which will cause the light group to illuminate, a notification is sent via the Pushover API (paid app from app stores) to a device of your choice that's registered with your account, advising the time of the event and to check CCTV.

If one PIR causes the light group to trigger, or it is triggerd manually by an app or switch, any other copies of this script that also trigger the same light(s) will notice and consider the lights to be under manual control, ensuring they don't interfere with whatever has been manually set.

## Octocoupler circuit

The octocoupler, also described as an opto-isolator, isolates the mains/line voltage from the Raspberry Pi and is the safest way to detect AC voltage using a Raspberry Pi since the Pi is never in contact with the high AC voltage.

The octocoupler circuit used was purchased from eBay and is described as:

`240V 220V AC Mains Sensor opto-isolator optoisolator optocoupler 5V 3.3V Arduino`

![ebay seller](https://github.com/lwsrbrts/Pwsh-Opto-Docker/raw/master/ebay-seller.png "ebay seller")


## Pin layout

The octo-coupler is connected to the Raspberry Pi as follows:

![Pin layout for octo-coupler](https://github.com/lwsrbrts/Pwsh-Opto-Docker/raw/master/Pin-layout.png "Pin layout for octo-coupler")

PowerShell uses WiringPi pin numbering so the octo-coupler `OUT` is connected to physical pin `7` on the Raspberry Pi's GPIO, which is also WiringPi pin `7`. If you are not using physical pin `7`, the WiringPi pin is (obviously) different. For example, physical pin `26` on the Raspberry Pi GPIO is WiringPi pin `11` as far as the PowerShell IoT module is concerned.

## Install Docker

Go to `https://get.docker.com/`

or

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
```

## If you need git on the RaspberryPi

```powershell
sudo apt-get install git
```

## Clone the repo & build the image

The repo is private, you'll need to log in.

```powershell
git clone https://github.com/lwsrbrts/Pwsh-Opto-Docker.git ~/Pwsh-Opto-Docker/
```

## Build the image

```powershell
cd ~/Pwsh-Opto-Docker/

docker build --tag pwsh-opto .
```

Builds the image locally and tags it as `pwsh-opto:latest`

## Environment variables

These environment variables must be passed to the container (PowerShell script ultimately).

* `TZ` - The [timezone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) in which your container is running. If not set, it'll be UTC.
* `BRIDGEIP` - The local IP address of the Hue bridge.
* `APIKEY` - The Hue User ID or API Key as provided by the bridge.
* `EVENINGSCENE` - The Hue scene ID of the evening (primary or perhaps brightest) scene to use throughout most of the evening.
* `NIGHTSCENE` - The scene ID of the night time scene to use so that the lights aren't blaring at 1am.
* `PUSHTOKEN` - The Pushover token associated with the application.
* `PUSHUSER` - The Pushover user.
* `PUSHDEVICE` - The Pushover device identifier.
* `GPIOPIN` - Which GPIO pin is the optocoupler triggering for this Raspberry Pi. Front = `7`, Side = `11`
* `GROUPID` - The Hue Bridge group ID for the group that's being controlled by the script.

## Example

This is an example docker run command which assumes the image has been built and called `pwsh-opto:latest`.

### Interactive, single execution, named

``` powershell
docker run --rm -it --privileged \
--name pwsh-opto \
-h FRONT \
-e TZ=Europe/London
-e BRIDGEIP=192.168.1.12 \
-e APIKEY=abcdefghijklmnopqrstuvwxyz \
-e EVENINGSCENE=abcdefghijklmnopqrstuvwxyz \
-e NIGHTSCENE=abcdefghijklmnopqrstuvwxyz \
-e PUSHTOKEN=abcdefghijklmnopqrstuvwxyz \
-e PUSHUSER=abcdefghijklmnopqrstuvwxyz \
-e PUSHDEVICE=pixel3xl \
-e GPIOPIN=7 \
-e GROUPID=21 \
pwsh-opto:latest
```

### Auto-healing, detached, named

``` powershell
docker run --privileged -d \
--name pwsh-opto \
--restart=unless-stopped \
-h FRONT \
-e TZ=Europe/London
-e BRIDGEIP=192.168.1.12 \
-e APIKEY=abcdefghijklmnopqrstuvwxyz \
-e EVENINGSCENE=abcdefghijklmnopqrstuvwxyz \
-e NIGHTSCENE=abcdefghijklmnopqrstuvwxyz \
-e PUSHTOKEN=abcdefghijklmnopqrstuvwxyz \
-e PUSHUSER=abcdefghijklmnopqrstuvwxyz \
-e PUSHDEVICE=pixel3xl \
-e GPIOPIN=7 \
-e GROUPID=21 \
pwsh-opto:latest
```

* `-h` will set the hostname which is used in the Pushover notifications, naming the sensor that is emitting the notification.
* `--privileged` is used to ensure the Raspberry Pi can access the GPIO pins.

### Review logs from a container

Redirect standard and error logs to a file.

`docker container logs pwsh-opto >& logs.log`

### Updating the container from GitHub

Basically pull the Dockerfile and script from the GitHub repo and build it again then run once a new image is built.

```powershell
docker container stop pwsh-opto

docker container rm pwsh-opto

cd ~/Pwsh-Opto-Docker/

git pull

docker build --tag pwsh-opto .
```