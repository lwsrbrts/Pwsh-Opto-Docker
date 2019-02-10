$ErrorActionPreference = "Stop" # Cause the container to fail (and restart if there's an issue.)
Import-Module PoSHue
Import-Module Microsoft.PowerShell.IoT

$Off = 1
$On = 0
$SensorName = $env:HOSTNAME
$Pin = $env:GPIOPIN

while ((Get-GpioPin -Id $Pin).Value -eq $On) {
    "Power is currently ON. Waiting for initial OFF state to begin monitoring..."
    Start-Sleep -Seconds 10
}

# Hue Stuff
$HueBridgeIP = $env:BRIDGEIP
$HueUserID = $env:APIKEY
[int]$HueGroup = $env:GROUPID
$Garage = [HueGroup]::new($HueGroup, $HueBridgeIP, $HueUserID)
$Scene = [HueScene]::new($HueBridgeIP, $HueUserID) # For setting scenes.
$Concentrate = $env:EVENINGSCENE # Concentrate scene from the Hue Bridge for Group 21
$Night = $env:NIGHTSCENE # Night scene from the Hue Bridge for Group 21

# Pushover notifications
# Set up the parameters for the notification.
$Parameters = @{}
$Parameters.Add('token', $env:PUSHTOKEN)
$Parameters.Add('user', $env:PUSHUSER)
$Parameters.Add('device', $env:PUSHDEVICE)
$Parameters.Add('title', 'Motion detected!')
$Parameters.Add('priority', 0)
$Parameters.Add('sound', 'pushover')

"Ready..."

$CurrentState = $Off
$PreviousState = $Off
$Controlled = $true # Is the light currently being controlled by the PIR logic.

# Create an endless loop for monitoring.
while ($true) {
    $CurrentState = (Get-GpioPin -Id $Pin).Value
    $Garage.GetStatus() # Update the state of the group.

    if ($Controlled -eq $false) {
        if ($Garage.AnyOn -eq $false) {
            "`n$(Get-Date -f "dd-MM-yyyy HH:mm:ss"): Light released from manual control."
            $Controlled = $true
        }
        else { Write-Host "." -NoNewline }
        Start-Sleep -Seconds 10
        continue
    }

    if (($CurrentState -eq $On) -and ($PreviousState -eq $Off) -and ($Controlled -eq $true)) {
        # Motion was detected because power to the octocoupler was switched on.
        "$(Get-Date -f "dd-MM-yyyy HH:mm:ss"): Power sensed, switching the light ON!"

        if (((Get-Date) -gt '23:00') -or ((Get-Date) -lt '05:00')) {
            $Scene.SetHueScene($Night) | Out-Null
            if (((Get-Date) -gt '23:00') -or ((Get-Date) -lt '01:00')) { } # If between 23:00 and 01:00 then do nothing
            elseif (((Get-Date) -gt '01:00') -and ((Get-Date) -lt '05:00')) { # else we raise a notification
                # Late night detection should be investigated. Raise a notification via Pushover.
                $Parameters.Add('message', "$(Get-Date -f "dd-MM-yyyy HH:mm:ss"): Motion was detected by $($SensorName.ToLower()) motion sensor during the early hours. Consult CCTV.")
                $Response = Invoke-RestMethod -Uri 'https://api.pushover.net/1/messages.json' -Method 'Post' -Body (ConvertTo-Json $Parameters) -ContentType 'application/json'
                $Parameters.Remove('message')
            }
        }
        else {
            $Scene.SetHueScene($Concentrate) | Out-Null
        }
        $PreviousState = $On
        $Controlled = $true
    }
    elseif (($CurrentState -eq $Off) -and ($PreviousState -eq $On) -and ($Controlled -eq $true)) {
        # Turn the light off
        "$(Get-Date -f "dd-MM-yyyy HH:mm:ss"): Power lost, switching the light OFF!"
        $Garage.SwitchHueGroup('Off')
        $PreviousState = $Off
        $Controlled = $true
    }
    elseif (($CurrentState -eq $Off) -and ($PreviousState -eq $Off) -and ($Garage.AnyOn -eq $true)) {
        "$(Get-Date -f "dd-MM-yyyy HH:mm:ss"): The light is now under manual control."
        $Controlled = $false # The light has been controlled manually.
    }
    Start-Sleep -Seconds 1
}
