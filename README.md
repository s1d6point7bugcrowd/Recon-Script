Disclaimer

Important: This script is intended for authorized security testing purposes only. Ensure you have explicit permission to test any target before using this script. Unauthorized testing can be illegal and unethical. The authors of this script are not responsible for any misuse or damage caused by the use of this script. Use it responsibly and only on targets you have permission to test.



# Web Application Security Automation Script

This script automates the process of discovering, enumerating, and testing web application targets. It allows the user to specify a target domain or a single URL, and filter out out-of-scope (OOS) URLs and subdomains. The script uses various tools to identify alive subdomains, probe for HTTP endpoints, crawl for additional URLs, and test for vulnerabilities using Nuclei.

## Prerequisites

Before running the script, ensure that the following tools are installed and available in your PATH:

- `subfinder`
- `dnsx`
- `httpx`
- `unfurl`
- `nuclei`
- `anew`

   Each line is checked for the presence of "medium", "high", or "critical" keywords, and the appropriate announcement is made using espeak.

Ensure you have installed espeak, and then run this script. This will provide real-time voice announcements for detected vulnerabilities as the scan progresses.

## Usage

1. Clone this repository or download the script to your local machine.
2. Make the script executable:

    ```bash
    chmod +x security-automation.sh
    ```

3. Run the script:

    ```bash
    ./security-automation.sh
    ```

4. Follow the prompts to enter the target domain or URL, and out-of-scope URLs and subdomains.

## Script Workflow

1. **Target Input**: The script prompts the user to enter a target domain or URL.
2. **OOS Input**: The script prompts the user to enter out-of-scope URLs and subdomains as a comma-separated list.
3. **Subdomain Enumeration**: Using `subfinder` and `dnsx`, the script discovers and validates subdomains.
4. **HTTP Probing**: The script uses `httpx` to identify HTTP endpoints and checks their status codes. 
5. **URL Formatting**: Using `unfurl`, the script formats URLs to a consistent scheme.
6. **OOS Filtering**: The script filters out the out-of-scope URLs and subdomains.
7. **Vulnerability Scanning**: The script runs Nuclei against the filtered URLs to identify potential vulnerabilities.





Contributions are welcome! Please read the contributing guidelines before submitting pull requests.
License

Distributed under the MIT License. See LICENSE for more information.
Acknowledgments

Thanks to the developers of the integrated tools.
Special thanks to ProjectDiscovery for their open-source tools used in this script.
