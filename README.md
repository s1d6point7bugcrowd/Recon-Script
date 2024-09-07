Disclaimer

Important: This script is intended for authorized security testing purposes only. Ensure you have explicit permission to test any target before using this script. Unauthorized testing can be illegal and unethical. The authors of this script are not responsible for any misuse or damage caused by the use of this script. Use it responsibly and only on targets you have permission to test.



# Nuclei Automation Script

This script automates the process of running security scans using Nuclei, a powerful vulnerability scanner, with additional options for voice notifications, proxy usage, cloud integration with ProjectDiscovery Cloud Platform (PDCP), and logging of scan times.

## Features

***Added secure version with forensic time-stamps and encryption (secure-recon-script.sh)***
***Added new HTTPX Cloud Feature Option***

- **Voice Notifications**: Get voice alerts for various actions and vulnerability detections.
- **Proxychains Support**: Run the scans through a proxy for anonymization or bypassing restrictions.
- **Nuclei Cloud Features**: Option to upload scan results to the ProjectDiscovery Cloud Platform (PDCP).
- **Out-of-Scope Filtering**: Filter out-of-scope domains or URLs from the scan targets.
- **Bug Bounty Customization**: Add custom headers to the scan requests for bug bounty identification.
- **Logging**: Start and stop times of each scan are recorded for auditing purposes.

## Prerequisites

- **Nuclei**: Ensure that Nuclei is installed on your system.
- **Proxychains**: (Optional) Install Proxychains if you plan to use the proxy feature.
- **Espeak**: Install Espeak for voice notifications.
- **Subfinder**: Install Subfinder for subdomain enumeration.
- **Dnsx**: Install Dnsx for DNS resolution and subdomain discovery.
- **Httpx**: Install Httpx for probing live hosts.

## Installation

1. Clone the repository or download the script.
2. Make the script executable:
   ```bash
   chmod +x nuclei-automation.sh


Ensure all required tools (nuclei, proxychains, espeak, subfinder, dnsx, httpx) are installed and accessible in your PATH.




Options and Prompts

    Voice Notifications: Enable or disable voice notifications during the scan.
    Data Storage: Choose whether to store scan data temporarily or permanently.
    Proxychains: Optionally run the scan through a proxy using Proxychains.
    Nuclei Cloud Features: Decide whether to upload the scan results to the Nuclei cloud (PDCP).
    Scan Target: Choose between scanning a domain or a single URL.
    Out-of-Scope Patterns: Specify any out-of-scope patterns to exclude from the scan.
    Bug Bounty Program Name: Add a custom header with your bug bounty identifier.
    Nuclei Templates: Specify paths and tags for Nuclei templates to use during the scan.
    Severity Levels: Define the severity levels for the vulnerabilities you want to detect.
    Rate Limit: Set the rate limit for Nuclei requests per second.
    DNSX Wordlist: Provide the path to a wordlist for DNS enumeration.

Logging

The script records the start and stop time of each scan in a log file (nuclei-scan-log.txt) located in the data directory.
Example

Here is an example of how the script might be used:

    Run the script:

    bash

    ./nuclei-automation.sh

    Follow the prompts to configure the scan.
    Review the scan output and log file for the scan duration and results.

License

This project is licensed under the MIT License.

Acknowledgments

    ProjectDiscovery: For providing Nuclei, Subfinder, Dnsx, and Httpx.
    Bug Bounty Community: For ongoing contributions to security research.
