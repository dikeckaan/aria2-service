# aria2-service
Download and install aria2 as windows service

## Usage

### Windows Usage
* Open a powershell and paste the lines below
```powershell
Set-ExecutionPolicy Bypass -scope Process -Force
irm "[https://raw.githubusercontent.com/mguludag/aria2-service/refs/heads/main/aria2.ps1](https://raw.githubusercontent.com/mguludag/aria2-service/refs/heads/main/aria2.ps1)" | iex
````

  * After aria2c installation, intall the [Aria2 Explorer](https://chromewebstore.google.com/detail/aria2-explorer/mpkodccbngfoacfalldjimigbofkhgjn) extension in chromium based browser then setup it.

-----

### macOS Usage

This setup requires `aria2c` to be pre-installed, preferably via **Homebrew**.

1.  **Install aria2c via Homebrew (If necessary):**
    ```bash
    brew install aria2
    ```
2.  **Run the Installation Script:**
    ```bash
    bash aria2-MacOS.sh
    ```
3.  **Service Details:**
      * The service is named `com.user.aria2rpc`.
      * The configuration file is located at `~/Library/Application Support/aria2/aria2.conf`.
      * The downloads directory is `~/Downloads`.
      * The connection for Motrix is `http://localhost:6800`.
      * Error and output logs are found in `~/Library/Application Support/aria2/*.log`.
