# Web Application Security Testing Automation

**Disclaimer:**
This script is intended for authorized security testing purposes only. Ensure you have explicit permission to test any target before using this script. Unauthorized testing can be illegal and unethical. The authors of this script are not responsible for any misuse or damage caused by the use of this script. Use it responsibly and only on targets you have permission to test.

## Table of Contents

1. [Introduction](#introduction)
2. [Features](#features)
3. [Prerequisites](#prerequisites)
4. [Usage](#usage)
5. [Prompted Inputs](#prompted-inputs)
6. [File Outputs](#file-outputs)
7. [Disclaimer](#disclaimer)
8. [Contributing](#contributing)
9. [License](#license)
10. [Acknowledgments](#acknowledgments)

## Introduction

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



Parameters

    mode: Can be either domain or url, specifying the type of target.
    target: The domain name or URL you want to test.

./security_scan.sh domain example.com



Prompted Inputs

    Program Name: For the X-Bug-Bounty header.
    OOS Subdomains and URLs: Comma-separated list of out-of-scope patterns.
    Use Naabu: Whether to use naabu for port scanning.
    Store Files Locally: Whether to store files locally or use mktemp.
    Use Waybackurls: Whether to use waybackurls for historical URL discovery.

File Outputs

    subs.txt: Discovered subdomains.
    filtered-subs.txt: Filtered subdomains.
    alive-subs-ip.txt: Alive subdomains with IP addresses.
    alive-subs.txt: Alive subdomains.
    openports.txt: Open ports found by naabu.
    final-openports.txt: Filtered open ports.
    web-alive.txt: Web hosts that are alive.
    waybackurls.txt: URLs discovered by waybackurls.
    filtered-waybackurls.txt: Filtered wayback URLs.
    nuclei-ready.txt: URLs ready for nuclei scan.
    nuclei-results.txt: Results from nuclei scan.
    new-urls.txt: New URLs discovered by waybackurls.


    Often web developers keep making changes to the website’s front end, not the back end. If we only see the current web pages, we might miss out a few of the interesting endpoints which the developer removed from the page but still exist in the back end. 

    Sometimes when some flaws are found in websites, instead of fixing the flaw, developers just remove it from the website. The thinking behind this is that if this is removed from the site then it cannot be accessed as people will never know about it.  

Using the Wayback machine we can get new endpoints and increase our attack surface.



Disclaimer

Important: This script is intended for authorized security testing purposes only. Ensure you have explicit permission to test any target before using this script. Unauthorized testing can be illegal and unethical. The authors of this script are not responsible for any misuse or damage caused by the use of this script. Use it responsibly and only on targets you have permission to test.
Contributing

Contributions are welcome! Please read the contributing guidelines before submitting pull requests.
License

Distributed under the MIT License. See LICENSE for more information.
Acknowledgments

    Thanks to the developers of the integrated tools.
    Special thanks to ProjectDiscovery for their open-source tools used in this script.
