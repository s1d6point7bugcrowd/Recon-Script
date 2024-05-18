# Web Application Reconnaissance Script

## Disclaimer

**DISCLAIMER:** This script is intended for authorized penetration testing and research purposes only. Unauthorized use of this script against systems you do not own or have explicit permission to test is illegal and unethical. The author is not responsible for any misuse or damage caused by this script.

## Overview

This reconnaissance script automates the process of gathering information about a target domain or URL. It performs subdomain enumeration, resolves subdomains to IP addresses, checks for live hosts, scans for open ports, and identifies web services. The script ensures rate-limiting to comply with responsible disclosure policies and integrates various tools.

### Key Features

- Subdomain enumeration and filtering
- IP resolution and live host checking
- Open port scanning with rate-limiting
- Web service identification and crawling
- Extraction and analysis of interesting URLs
- Historical URL retrieval


### Tools Integrated

- `subfinder`: For subdomain enumeration
- `dnsx`: For resolving subdomains to IP addresses
- `naabu`: For port scanning
- `httpx`: For checking live web services
- `gospider`: For crawling web services
- `unfurl`: For URL formatting
- `gau`: For retrieving historical URLs
- `nuclei`: For vulnerability scanning


### Usage

```sh
./recon.sh <mode> <target>


./recon.sh domain example.com


Port scanning is optional (user prompted)
