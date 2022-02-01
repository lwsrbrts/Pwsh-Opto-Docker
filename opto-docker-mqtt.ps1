$ErrorActionPreference = "Stop" # Cause the container to fail (and restart if there's an issue.)

Import-Module Microsoft.PowerShell.IoT

$Off = 1
$On = 0
$Pin = $env:GPIOPIN
$hassServer = $env:HASSURL
$sensorName = $env:SENSORNAME # must include scheme
$Token = $env:LONGLIVEDTOKEN | ConvertTo-SecureString -AsPlainText -Force

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

        $Body = @{state='ON'}

        Invoke-RestMethod -Uri $hassServer/api/states/$sensorName `
            -Method Post `
            -ContentType 'application/json' `
            -Body (ConvertTo-Json $Body -Depth 4) `
            -Authentication 'Bearer' `
            -Token $Token `
            -AllowUnencryptedAuthentication
        #        
        $PreviousState = $On
    }
    elseif (($CurrentState -eq $Off) -and ($PreviousState -eq $On)) {

        "$(Get-Date -f "dd-MM-yyyy HH:mm:ss"): Emitting power OFF message."

        $Body = @{state='OFF'}

        Invoke-RestMethod -Uri $hassServer/api/states/$sensorName `
            -Method Post `
            -ContentType 'application/json' `
            -Body (ConvertTo-Json $Body -Depth 4) `
            -Authentication 'Bearer' `
            -Token $Token `
            -AllowUnencryptedAuthentication

        $PreviousState = $Off
    }

    Start-Sleep -Seconds 1
}
