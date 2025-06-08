# aria2-service
Download and install aria2 as windows service

## Usage
* Open a powershell and paste the lines below
```powershell
Set-ExecutionPolicy Bypass -scope Process -Force
irm "https://raw.githubusercontent.com/mguludag/aria2-service/refs/heads/main/aria2.ps1" | iex

```
* After aria2c installation, intall the [Aria2 Explorer](https://chromewebstore.google.com/detail/aria2-explorer/mpkodccbngfoacfalldjimigbofkhgjn) extension in chromium based browser then setup it.
