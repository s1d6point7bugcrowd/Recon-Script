#!/bin/bash



# Function to read user input for the target domain or URL

read -p "Enter the target domain or URL (e.g., example.com or https://example.com): " TARGET



# Function to read user input for out-of-scope URLs and subdomains

read -p "Enter out-of-scope URLs and subdomains (comma-separated): " OOS_ENTRIES



# Convert comma-separated OOS entries to newline-separated for filtering

OOS_ENTRIES_FILE="${TARGET//[^a-zA-Z0-9]/_}-oos-entries.txt"

echo "$OOS_ENTRIES" | tr ',' '\n' > $OOS_ENTRIES_FILE



# Filter function to exclude OOS entries

filter_oos() {

  grep -v -f $OOS_ENTRIES_FILE

}



if [[ $TARGET == http* ]]; then

  # If a single URL is provided, process only this URL

  echo $TARGET | anew ${TARGET//[^a-zA-Z0-9]/_}-single-url.txt

  httpx -silent -title -status-code -mc 200,403,400,500 < ${TARGET//[^a-zA-Z0-9]/_}-single-url.txt | anew ${TARGET//[^a-zA-Z0-9]/_}-web-alive.txt

  echo $TARGET | gospider -t 10 -o ${TARGET//[^a-zA-Z0-9]/_}crawl | anew ${TARGET//[^a-zA-Z0-9]/_}-crawled.txt

  unfurl format %s://dtp < ${TARGET//[^a-zA-Z0-9]/_}-crawled.txt | anew ${TARGET//[^a-zA-Z0-9]/_}-crawled-interesting.txt

  awk '{print $1}' < ${TARGET//[^a-zA-Z0-9]/_}-crawled-interesting.txt | gau -b eot,svg,woff,ttf,png,jpg,gif,otf,bmp,pdf,mp3,mp4,mov --subs | anew ${TARGET//[^a-zA-Z0-9]/_}-gau.txt

  httpx -silent -title -status-code -mc 200,403,400,500 < ${TARGET//[^a-zA-Z0-9]/_}-gau.txt | anew ${TARGET//[^a-zA-Z0-9]/_}-web-alive.txt

else

  # If a domain is provided, perform the full process

  subfinder -d $TARGET -silent | anew ${TARGET//[^a-zA-Z0-9]/_}-subs.txt && \

  dnsx -resp -silent < ${TARGET//[^a-zA-Z0-9]/_}-subs.txt | anew ${TARGET//[^a-zA-Z0-9]/_}-alive-subs-ip.txt && \

  awk '{print $1}' < ${TARGET//[^a-zA-Z0-9]/_}-alive-subs-ip.txt | anew ${TARGET//[^a-zA-Z0-9]/_}-alive-subs.txt && \

  httpx -silent -title -status-code -mc 200,403,400,500 < ${TARGET//[^a-zA-Z0-9]/_}-alive-subs.txt | anew ${TARGET//[^a-zA-Z0-9]/_}-web-alive.txt && \

  awk '{print $1}' < ${TARGET//[^a-zA-Z0-9]/_}-web-alive.txt | gospider -t 10 -o ${TARGET//[^a-zA-Z0-9]/_}crawl | anew ${TARGET//[^a-zA-Z0-9]/_}-crawled.txt && \

  unfurl format %s://dtp < ${TARGET//[^a-zA-Z0-9]/_}-crawled.txt | anew ${TARGET//[^a-zA-Z0-9]/_}-crawled-interesting.txt && \

  awk '{print $1}' < ${TARGET//[^a-zA-Z0-9]/_}-crawled-interesting.txt | gau -b eot,svg,woff,ttf,png,jpg,gif,otf,bmp,pdf,mp3,mp4,mov --subs | anew ${TARGET//[^a-zA-Z0-9]/_}-gau.txt && \

  httpx -silent -title -status-code -mc 200,403,400,500 < ${TARGET//[^a-zA-Z0-9]/_}-gau.txt | anew ${TARGET//[^a-zA-Z0-9]/_}-web-alive.txt

fi



# Apply the OOS filter to the web-alive results

filter_oos < ${TARGET//[^a-zA-Z0-9]/_}-web-alive.txt | tee ${TARGET//[^a-zA-Z0-9]/_}-web-alive-filtered.txt



# Run nuclei on the filtered results

awk '{print $1}' < ${TARGET//[^a-zA-Z0-9]/_}-web-alive-filtered.txt | nuclei -ss template-spray -H "X-Bug-Bounty: researcher" | tee ${TARGET//[^a-zA-Z0-9]/_}-nuclei-output.txt

