$ErrorActionPreference = "Stop" # Cause the container to fail (and restart if there's an issue.)

Import-Module Microsoft.PowerShell.IoT

$Off = 1
$On = 0
$SensorName = $env:HOSTNAME
$Pin = $env:GPIOPIN
$mqttServer = $env:MQTTSERVER

while ((Get-GpioPin -Id $Pin).Value -eq $On) {
    "Power is currently ON. Waiting for initial OFF state to begin monitoring..."
    Start-Sleep -Seconds 10
}

"Ready..."

$CurrentState = $Off
$PreviousState = $Off

# Create an endless loop for monitoring.
while ($true) {
    $CurrentState = (Get-GpioPin -Id $Pin).Value

    if (($CurrentState -eq $On) -and ($PreviousState -eq $Off)) {

        "$(Get-Date -f "dd-MM-yyyy HH:mm:ss"): Emitting power ON message."

        /usr/bin/mosquitto_pub -h $mqttServer -t "garage/$SensorName" -i $SensorName --% -m "{"""state""":"""ON"""}" --repeat 3 --repeat-delay 1
        
        $PreviousState = $On
    }
    elseif (($CurrentState -eq $Off) -and ($PreviousState -eq $On)) {

        "$(Get-Date -f "dd-MM-yyyy HH:mm:ss"): Emitting power OFF message."

        /usr/bin/mosquitto_pub -h $mqttServer -t "garage/$SensorName" -i $SensorName --% -m "{"""state""":"""OFF"""}" --repeat 3 --repeat-delay 1

        $PreviousState = $Off
    }

    Start-Sleep -Seconds 1
}
