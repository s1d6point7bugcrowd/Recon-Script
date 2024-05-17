#!/bin/bash

# Check if sufficient arguments are passed
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <mode> <target>"
    echo "Modes:"
    echo "  domain   Target is a domain name"
    echo "  url      Target is a specific URL"
    exit 1
fi

MODE="$1" # 'domain' or 'url'
TARGET="$2"

# Prompt for the program name
read -p "Enter the program name for the X-Bug-Bounty header: " PROGRAM_NAME

# Validate the program name input
if [ -z "$PROGRAM_NAME" ]; then
    echo "Program name is required. Exiting."
    exit 1
fi

# Prompt for OOS subdomains (comma-separated)
read -p "Enter Out-Of-Scope subdomains (comma-separated, leave blank for none): " OOS_SUBDOMAINS

# Convert OOS subdomains into grep-friendly patterns
if [ -n "$OOS_SUBDOMAINS" ]; then
    OOS_PATTERNS=$(echo "$OOS_SUBDOMAINS" | tr ',' '\\n')
    FILTER_CMD="grep -vFf <(echo \\"$OOS_PATTERNS\\")"
else
    FILTER_CMD="cat"
fi

# Show the excluded subdomains
if [ -n "$OOS_SUBDOMAINS" ]; then
    echo "The following subdomains will be excluded from scanning:"
    echo "$OOS_SUBDOMAINS"
else
    echo "No subdomains will be excluded from scanning."
fi

# Construct the custom header
CUSTOM_HEADER="X-Bug-Bounty:researcher@$PROGRAM_NAME"
echo "Using custom header: $CUSTOM_HEADER"

# Conditional execution based on mode
if [ "$MODE" == "domain" ]; then
    subfinder -d "$TARGET" -silent | eval "$FILTER_CMD" | anew "${TARGET}-subs.txt" && \
    dnsx -resp -silent < "${TARGET}-subs.txt" | anew "${TARGET}-alive-subs-ip.txt" && \
    awk '{print $1}' < "${TARGET}-alive-subs-ip.txt" | anew "${TARGET}-alive-subs.txt" && \
    sudo naabu -top-ports 1000 -rate 5 -c 25 -silent < "${TARGET}-alive-subs.txt" | anew "${TARGET}-openports.txt" && \
    cut -d ":" -f1 < "${TARGET}-openports.txt" | sudo naabu | anew "${TARGET}-openports.txt" && \
    httpx -td -silent --rate-limit 5 -title -status-code -mc 200,403,400,500 < "${TARGET}-openports.txt" | anew "${TARGET}-web-alive.txt" && \
    awk '{print $1}' < "${TARGET}-web-alive.txt" | gospider -t 10 -o "${TARGET}crawl" | anew "${TARGET}-crawled.txt" && \
    unfurl format %s://%d%p < "${TARGET}-crawled.txt" | httpx -td --rate-limit 5 -silent -title -status-code | anew "${TARGET}-crawled-interesting.txt" && \
    grep -E "(admin|dashboard|control|panel|manage|login|signin|signup|register|backup|config|secret|token|error|api|v1|v2|graphql|\\.js)" "${TARGET}-crawled-interesting.txt" | anew "${TARGET}-interesting.txt" && \
    awk '{print $1}' < "${TARGET}-interesting.txt" | gau -b eot,svg,woff,ttf,png,jpg,gif,otf,bmp,pdf,mp3,mp4,mov --subs | anew "${TARGET}-gau.txt" && \
    httpx -silent --rate-limit 5 -title -status-code -mc 200,301,302 < "${TARGET}-gau.txt" | anew "${TARGET}-web-alive.txt" && \
    awk '{print $1}' < "${TARGET}-web-alive.txt" | nuclei -rl 5 -ss template-spray -H "$CUSTOM_HEADER"

    # Save in-scope subdomains to subdomains.txt
    cat "${TARGET}-subs.txt" > subdomains.txt

    # Inform the user about subdomain takeover detection
    echo "Subdomain takeover detection in progress..."

    # Run subzy to check for subdomain takeovers
    subzy run --targets subdomains.txt --hide_fails | anew "${TARGET}-subzy-results.txt"

elif [ "$MODE" == "url" ]; then
    echo "$TARGET" | nuclei -include-tags misc -rl 5 -ss template-spray -H "$CUSTOM_HEADER"

else
    echo "Invalid mode specified. Use 'domain' or 'url'."
    exit 1
fi
