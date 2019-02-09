# Pwsh-Opto-Docker
Docker container to run a PowerShell script which monitors GPIO pins for an opto-coupler circuit triggered by an AC voltage PIR. Additionally sends notifications using Pushover if the PIR is triggered between 1am and 5am as these are unsociable hours.

# Build the image
```powershell
git clone https://github.com/lwsrbrts/Pwsh-Opto-Docker.git ~/Pwsh-Opto-Docker/

cd ~/Pwsh-Opto-Docker/

docker build --tag pwsh-opto .
```

Builds the image locally and tags it as `pwsh-opto:latest`

## Environment variables

The environment variables must be passed to the container (PowerShell script ultimately).

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

This is an example docker run command which assumes the image has been built and called pwsh-opto:latest.

``` powershell
docker run --rm -it --privileged -h FRONT \
-e BRIDGEIP=192.168.1.12 \
-e APIKEY=abcdefghijklmnopqrstuvwxyz \
-e EVENINGSCENE=abcdefghijklmnopqrstuvwxyz \
-e NIGHTSCENE=abcdefghijklmnopqrstuvwxyz \
-e PUSHTOKEN=abcdefghijklmnopqrstuvwxyz \
-e PUSHUSER=abcdefghijklmnopqrstuvwxyz \
-e PUSHDEVICE=pixel3xl \
-e GPIOPIN=11 \
-e GROUPID=21
pwsh-opto:latest
```

* The host name should be set as this is used for the notifications. `-h`
* `--privileged` is used to ensure the RasPberry Pi can access the GPIO pins