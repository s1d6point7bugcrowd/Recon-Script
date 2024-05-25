Disclaimer

Important: This script is intended for authorized security testing purposes only. Ensure you have explicit permission to test any target before using this script. Unauthorized testing can be illegal and unethical. The authors of this script are not responsible for any misuse or damage caused by the use of this script. Use it responsibly and only on targets you have permission to test.



# Automated Recon and Vulnerability Scanning Script

This script automates the process of reconnaissance and vulnerability scanning on a given domain or URL. It uses various tools like `subfinder`, `dnsx`, `httpx`, `naabu`, `waybackurls`, and `nuclei` to perform these tasks.

## Features

- Subdomain discovery using `subfinder`
- DNS resolution using `dnsx`
- HTTP probing using `httpx`
- Port scanning using `naabu` (optional)
- Historical URL discovery using `waybackurls` (optional)
- Vulnerability scanning using `nuclei`
- Custom headers for bug bounty programs
- Out-of-scope (OOS) subdomain and URL filtering
- Blacklisted file type filtering

## Prerequisites

Make sure you have the following tools installed and added to your PATH:

- subfinder
- dnsx
- httpx
- naabu (optional)
- waybackurls (optional)
- nuclei

## Usage

```bash
./recon.sh <mode> <target>



Parameters

    mode: The mode of operation. It can be either domain or url.
        domain: Target is a domain name.
        url: Target is a specific URL.
    target: The target domain or URL.

Example



./recon.sh domain example.com

Script Workflow

    Subdomain Discovery: Runs subfinder to discover subdomains.
    DNS Resolution: Uses dnsx to resolve discovered subdomains.
    HTTP Probing: Uses httpx to check for live web servers.
    Port Scanning: Optionally uses naabu for port scanning.
    Historical URLs: Optionally uses waybackurls to discover historical URLs.
    Vulnerability Scanning: Uses nuclei to scan for vulnerabilities.

Configuration
Custom Headers

The script will prompt for a custom header to use with nuclei scans, useful for bug bounty programs.
Out-of-Scope Subdomains and URLs

You can specify OOS subdomains and URLs, which the script will skip during scanning.
Wayback URLs

You can choose to use waybackurls to gather historical URLs for scanning.
Nuclei Templates and Tags

You can specify custom Nuclei templates or tags to use during the vulnerability scanning phase.
Prompts

The script will prompt you for the following information:

    Program name for the custom header.
    OOS subdomains and URLs (comma separated).
    Whether to use naabu for port scanning.
    Whether to store files locally.
    Whether to use waybackurls.
    Whether to use specific Nuclei templates or tags.

Example Workflow

    Run the script with domain mode:

    

./recon.sh domain example.com

Enter the program name for the custom header:



Enter the program name for the X-Bug-Bounty header: mybugbountyprogram

Enter OOS subdomains and URLs:



Enter OOS subdomains and URLs (comma separated): oos.example.com,anotheroos.example.com

Choose whether to use naabu for port scanning:



Do you want to use Naabu for port scanning? (yes/no): yes

Choose whether to store files locally:



Do you want to store files locally? (yes/no): no

Choose whether to use waybackurls:



Do you want to use waybackurls? (yes/no): yes

Choose whether to use specific Nuclei templates or tags:



Do you want to use specific Nuclei templates or tags? (yes/no): yes

Enter the path(s) to Nuclei templates or tags (comma separated):



    Enter the path(s) to Nuclei templates or tags (comma separated): tags,other-tags

The script will then proceed to perform the recon and vulnerability scanning based on the inputs provided.



Contributions are welcome! Please read the contributing guidelines before submitting pull requests.
License

Distributed under the MIT License. See LICENSE for more information.
Acknowledgments

    Thanks to the developers of the integrated tools.
    Special thanks to ProjectDiscovery for their open-source tools used in this script.
