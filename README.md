Disclaimer

Important: This script is intended for authorized security testing purposes only. Ensure you have explicit permission to test any target before using this script. Unauthorized testing can be illegal and unethical. The authors of this script are not responsible for any misuse or damage caused by the use of this script. Use it responsibly and only on targets you have permission to test.



# Web Application Security Automation Script


Overview

This script automates the process of subdomain discovery, filtering out-of-scope patterns, testing the responsiveness of discovered subdomains, and scanning for vulnerabilities using various tools like subfinder, dnsx, httpx, and nuclei. It also includes voice announcements for key events and the ability to use proxychains for network traffic.
Prerequisites

Ensure the following tools are installed and accessible in your PATH:

    subfinder
    dnsx
    httpx
    nuclei
    espeak
    proxychains (optional)
    anew
    lolcat

Script Usage
Running the Script

To run the script, use the following command:

bash

./subdomain_vuln_scan.sh

Script Prompts and Configurations

    Voice Announcements:
        Prompt: Do you want to enable voice announcements? (y/n)
        Functionality: Enables voice notifications using espeak.

    Data Storage:
        Prompt: Do you want to store the data permanently? (y/n)
        Functionality: Choose between temporary storage (/tmp) or permanent storage (./data).

    Proxychains Usage:
        Prompt: Do you want to use proxychains? (y/n)
        Functionality: Option to use proxychains for network traffic.

    Scan Type:
        Prompt: Do you want to test a domain (1) or a single URL (2)?
        Functionality: Decide to scan a domain or a single URL.

    Out-of-Scope Patterns:
        Prompt: Enter comma-separated out-of-scope patterns (e.g., *.example.com, example.example.com):
        Functionality: Input patterns to exclude from scanning.

    Bug Bounty Program Name:
        Prompt: Enter the bug bounty program name:
        Functionality: Input program name for a custom header.

    Nuclei Template Paths:
        Prompt: Enter the Nuclei template paths (comma-separated):
        Functionality: Specify paths for nuclei templates.

    Nuclei Template Tags:
        Prompt: Enter the Nuclei template tags (comma-separated):
        Functionality: Specify tags for nuclei templates.

    Nuclei Severity Levels:
        Prompt: Enter the Nuclei severity levels (comma-separated):
        Functionality: Input severity levels to filter scan results.

    DNSX Wordlist:
        Prompt: Enter the path to the dnsx wordlist:
        Functionality: Provide a path to a wordlist for dnsx.

Interrupting the DNSX Scan

A trap function has been added to allow users to stop the dnsx scan by sending an interrupt signal (Ctrl+C). This will use the subdomains collected up to that point and continue the script without breaking.
Functions
announce_message

    Usage: announce_message "Your message here"
    Description: Announces a message using espeak if voice notifications are enabled.

run_nuclei

    Usage: run_nuclei target_file
    Description: Runs nuclei on the targets listed in the specified file.

filter_oos

    Usage: filter_oos input_file output_file
    Description: Filters out-of-scope patterns from the input file and writes the in-scope patterns to the output file.

find_new_subdomains

    Usage: find_new_subdomains original_file new_file output_file
    Description: Finds new subdomains discovered by dnsx and writes them to the output file.

announce_vulnerability

    Usage: announce_vulnerability severity
    Description: Announces the detected vulnerability severity.

Example Workflow

    Scan a Domain:
        Enter 1 when prompted to scan a domain.
        Provide the target domain.
        Follow the prompts to configure out-of-scope patterns, nuclei template paths, tags, and severity levels.
        The script will discover subdomains, filter them, and run dnsx, httpx, and nuclei scans on the valid subdomains.

    Scan a Single URL:
        Enter 2 when prompted to scan a single URL.
        Provide the target URL.
        Follow the prompts to configure out-of-scope patterns, nuclei template paths, tags, and severity levels.
        The script will test the URL for responsiveness and run a nuclei scan if the URL is in scope.

Notes

    Ensure you have the necessary permissions to scan the target domains/URLs.
    The script uses trap to handle interruptions during the dnsx scan gracefully.
    Voice notifications require espeak to be installed.
## License

This project is licensed under the MIT License. See the LICENSE file for details.

---

Coded by: s1d6p01nt7

Thanks to the developers of the integrated tools.
Special thanks to ProjectDiscovery for their open-source tools used in this script.
