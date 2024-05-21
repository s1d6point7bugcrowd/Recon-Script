# Web Application Security Testing Automation

This repository contains a Bash script designed to automate various stages of web application security testing. It integrates multiple security tools to perform subdomain enumeration, DNS resolution, port scanning, and vulnerability scanning.

## Features

- **Subdomain Discovery**: Leverages `subfinder` to discover subdomains associated with a given domain.
- **DNS Resolution**: Utilizes `dnsx` for quick DNS resolutions and to find alive subdomains.
- **Port Scanning**: Optionally uses `Naabu` to perform fast port scanning on discovered subdomains.
- **Content Discovery**: Integrates `waybackurls` for fetching known URLs from the Wayback Machine.
- **Live Endpoint Testing**: Uses `httpx` to check for live web endpoints and retrieve response titles and status codes.
- **Vulnerability Scanning**: Applies `Nuclei` for automated vulnerability scanning with custom headers to identify your testing traffic.

## Prerequisites

Before you run the script, make sure you have the following tools installed:
- [Subfinder](https://github.com/projectdiscovery/subfinder)
- [Dnsx](https://github.com/projectdiscovery/dnsx)
- [Naabu](https://github.com/projectdiscovery/naabu)
- [Httpx](https://github.com/projectdiscovery/httpx)
- [Waybackurls](https://github.com/tomnomnom/waybackurls)
- [Nuclei](https://github.com/projectdiscovery/nuclei)

## Usage

```bash
./security_scan.sh <mode> <target>



Parameters:

    mode: Can be either domain or url, specifying the type of target.
    target: The domain name or URL you want to test.

Example:

bash

./security_scan.sh domain example.com

Configuration

    Custom Headers: Set up a custom header X-Bug-Bounty for the requests to identify your traffic.
    Out-of-Scope Patterns: Define out-of-scope subdomains and URLs to exclude from testing.
    File Management: Choose whether to store results locally or in temporary files based on your needs.

Contributing

Contributions are welcome! Please read the contributing guidelines before submitting pull requests.
License

Distributed under the MIT License. See LICENSE for more information.
Contact


Acknowledgments

    Thanks to the developers of the integrated tools.
    Special thanks to ProjectDiscovery for their open-source tools used in this script.

