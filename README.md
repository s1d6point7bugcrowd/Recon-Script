Disclaimer

Important: This script is intended for authorized security testing purposes only. Ensure you have explicit permission to test any target before using this script. Unauthorized testing can be illegal and unethical. The authors of this script are not responsible for any misuse or damage caused by the use of this script. Use it responsibly and only on targets you have permission to test.



# Bug Bounty Automation Script

This script automates several common tasks in bug bounty hunting, including subdomain enumeration, DNS resolution, HTTP probing, subdomain takeover detection, and vulnerability scanning using Nuclei.

## Features

- Subdomain enumeration with `subfinder`
- DNS resolution with `dnsx`
- HTTP probing with `httpx`
- Subdomain takeover detection with `subzy`
- Vulnerability scanning with `nuclei`

## Requirements

Ensure the following tools are installed and accessible from your PATH:

- `subfinder`
- `dnsx`
- `httpx`
- `subzy`
- `nuclei`

## Usage

```sh
./bugbounty-automation-beta.sh <mode> <target>


Modes

    domain: Target is a domain name (e.g., example.com)
    url: Target is a specific URL (e.g., https://example.com)


./bugbounty-automation-beta.sh domain example.com
./bugbounty-automation-beta.sh url https://example.com


Script Workflow

    Initialization and Input Validation:
        The script checks if sufficient arguments are passed.
        Normalizes and trims the MODE input.
        Prompts the user for various inputs such as program name, OOS subdomains, whether to store files locally, and specific Nuclei templates or tags.

    Custom Header Construction:
        Constructs a custom header using the provided program name.

    Out-of-Scope (OOS) Checking:
        Defines a function to check if a target is out of scope based on user-provided patterns.

    File Creation:
        Creates necessary files based on the user's choice to store files locally or use temporary files.

    Subdomain Enumeration and Takeover Detection (Domain Mode Only):
        Runs subfinder to gather subdomains.
        Uses dnsx for DNS resolution.
        Uses httpx for HTTP probing.
        Uses subzy for subdomain takeover detection.

    Vulnerability Scanning:
        Runs nuclei on the final set of URLs with user-defined or default templates and options.

Contributions are welcome! Please read the contributing guidelines before submitting pull requests.
License

Distributed under the MIT License. See LICENSE for more information.
Acknowledgments

    Thanks to the developers of the integrated tools.
    Special thanks to ProjectDiscovery for their open-source tools used in this script.
