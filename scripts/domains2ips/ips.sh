#!/bin/bash

domains=(
google.com
www.google.com
play.google.com
ogs.google.com
fonts.googleapis.com
notebooklm.google.com
notebooklm.google
gstatic.com
www.gstatic.com
ssl.gstatic.com
fonts.gstatic.com
googleusercontent.com
lh3.googleusercontent.com
nffaoalbilbmmfgbnbgppjihopabppdk
region1.analytics.google.com
www.googletagmanager.com
)

output_file="domains.csv" > "${output_file}"

for d in "${domains[@]}"; do
    for ip in $(dig +short "$d" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'); do
        echo "$ip,EUW,NL,NL" >> "${output_file}"
    done
done

echo "Saved CSV to $output_file"