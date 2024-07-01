Disclaimer

Important: This script is intended for authorized security testing purposes only. Ensure you have explicit permission to test any target before using this script. Unauthorized testing can be illegal and unethical. The authors of this script are not responsible for any misuse or damage caused by the use of this script. Use it responsibly and only on targets you have permission to test.



# Web Application Security Automation Script


This script is designed to automate the process of scanning domains and URLs for vulnerabilities using `subfinder`, `dnsx`, `httpx`, and `nuclei`. It includes options for enabling voice announcements, storing data, filtering out-of-scope patterns, and specifying custom Nuclei templates.

## Prerequisites

https://github.com/trickest/resolvers


Ensure the following tools are installed and available in your `PATH`:
- `espeak`
- `lolcat`
- `subfinder`
- `dnsx`
- `httpx`
- `nuclei`
- `anew`

## Usage

1. Clone or download this repository to your local machine.
2. Make the script executable: `chmod +x scan_script.sh`
3. Run the script: `./scan_script.sh`

## Script Workflow

### Voice Announcements
- **Prompt**: Enable voice announcements (`y/n`)
- If enabled, the script uses `espeak` for voice notifications.

### Data Storage
- **Prompt**: Store data permanently (`y/n`)
- If "no", data is stored in `/tmp`.
- If "yes", data is stored in `./data`.

### Scan Type
- **Prompt**: Scan a domain (1) or a single URL (2)
- Based on selection, the script proceeds with domain or URL scanning.

### Out-of-Scope Patterns
- **Prompt**: Enter comma-separated out-of-scope patterns (e.g., `*.example.com, example.example.com`)
- The script uses these patterns to filter results.

### Bug Bounty Program
- **Prompt**: Enter the bug bounty program name
- A custom header `X-Bug-Bounty` with the entered program name is used in HTTP requests.

### Nuclei Templates
- **Prompt**: Enter the Nuclei template paths (comma-separated)
- The script uses the specified templates for scanning.

## Domain Scan Workflow

1. **Subdomain Discovery**: Uses `subfinder` to discover subdomains.
2. **Out-of-Scope Filtering**: Filters subdomains based on out-of-scope patterns.
3. **DNS Resolution**: Uses `dnsx` to resolve and expand subdomain results.
4. **HTTP Probe**: Uses `httpx` to probe subdomains for HTTP services.
5. **Nuclei Scan**: Runs `nuclei` on the filtered and resolved subdomains.

## URL Scan Workflow

1. **HTTP Probe**: Uses `httpx` to probe the specified URL.
2. **Out-of-Scope Check**: Ensures the URL is in scope.
3. **Nuclei Scan**: Runs `nuclei` on the active and in-scope URL.

## Functions

### `announce_message`
Announces messages using `espeak` if voice announcements are enabled.

### `announce_vulnerability`
Announces the detection of vulnerabilities based on severity.

### `filter_oos`
Filters lines based on out-of-scope patterns.

### `find_new_subdomains`
Finds new subdomains discovered by `dnsx` and not present in the original subdomain list.

### `run_nuclei`
Runs `nuclei` on a list of targets with specified templates and custom headers.

## Example Commands

- `subfinder -d example.com -silent -all`
- `dnsx -resp -silent -r /path/to/resolvers.txt`
- `httpx -silent -title -rl 5 -status-code -td -mc 200,201,202,203,204,206,301,302,303,307,308 -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36"`
- `nuclei -rl 5 -ss template-spray -H "X-Bug-Bounty: s1d6p01nt7@program_name" -t /path/to/template.yaml`

## Notes

- Customize the script as per your requirements, especially the paths to tools and resolvers.
- Ensure appropriate permissions and scopes are in place for bug bounty programs.
- The script includes debug messages to assist in troubleshooting.

## License

This project is licensed under the MIT License. See the LICENSE file for details.

---

Coded by: s1d6p01nt7

Thanks to the developers of the integrated tools.
Special thanks to ProjectDiscovery for their open-source tools used in this script.
