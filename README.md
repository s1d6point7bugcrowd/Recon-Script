Disclaimer

Important: This script is intended for authorized security testing purposes only. Ensure you have explicit permission to test any target before using this script. Unauthorized testing can be illegal and unethical. The authors of this script are not responsible for any misuse or damage caused by the use of this script. Use it responsibly and only on targets you have permission to test.



# Bug Bounty Automation Script

This script automates the process of identifying vulnerabilities in web applications using a variety of tools such as `subfinder`, `dnsx`, `httpx`, `waybackurls`, `nuclei`, and optionally `naabu`.

## Features

- **Subdomain Enumeration**: Uses `subfinder` to find subdomains.
- **DNS Resolution**: Resolves subdomains to IP addresses using `dnsx`.
- **HTTP Probing**: Identifies live web servers using `httpx`.
- **Historical URL Discovery**: Optionally uses `waybackurls` to find historical URLs.
- **Vulnerability Scanning**: Uses `nuclei` to scan for vulnerabilities.
- **Port Scanning**: Optionally uses `naabu` for port scanning.
- **OOS Filtering**: Filters out-of-scope URLs and subdomains based on user input.

## Requirements

- `subfinder`
- `dnsx`
- `httpx`
- `waybackurls`
- `nuclei`
- `naabu` (optional)

## Usage

Clone the repository and navigate to the script directory:

```bash
git clone https://github.com/yourusername/bug-bounty-automation.git
cd bug-bounty-automation
chmod +x bugbounty-automation-beta.sh


Modes

    domain: The target is a domain name.
    url: The target is a specific URL.

Options

During execution, the script will prompt for the following inputs:

    Program name for the X-Bug-Bounty header: A custom header to identify your traffic.
    OOS subdomains and URLs: Comma-separated list of out-of-scope subdomains and URLs.
    Use Naabu for port scanning: (yes/no) Whether to use naabu for port scanning.
    Store files locally: (yes/no) Whether to save files locally.
    Use waybackurls: (yes/no) Whether to use waybackurls for historical URL discovery.
    Use specific Nuclei templates or tags: (yes/no) Whether to use specific Nuclei templates or tags.


Contributions are welcome! Please read the contributing guidelines before submitting pull requests.
License

Distributed under the MIT License. See LICENSE for more information.
Acknowledgments

    Thanks to the developers of the integrated tools.
    Special thanks to ProjectDiscovery for their open-source tools used in this script.
