#!/bin/sh

set -e -o pipefail
set -u
set -x

[ ! -f /usr/bin/curl ] && exit 1
[ ! -f /usr/bin/wget ] && exit 1

# This won't do much but we get a robot.txt and a file called opensource.
wget -x -r -np -k cms.gigaset.com/opensource
# Clumsy way to extract the links; xsltproc would also do ...
sed '/^<html>/,/^<body>/ d ; /^<h1>/ s/\s/\n/g' cms.gigaset.com/opensource | \
  sed -n '/href/ s/^.*"\(.*\)".*$/\1/p' > links.extracted

while read url ; do
    filename=$(basename "${url}")
    parent_directory=$(basename $(dirname "${url}"))
    # `--continue-at -` helps with subsequent executions of the script
    # `--output-dir` was added in 7.73.0 which is available in Debian Bullseye but not Debian Buster
    curl --create-dirs --output-dir "${parent_directory}" --continue-at - --verbose --remote-name --location "${url}"
    echo "${parent_directory}/${filename}" >> needs-checksum.txt
done < links.extracted

while read file_to_check ; do
    sha512sum "${file_to_check}" >> checksums.sha512
    sha256sum "${file_to_check}" >> checksums.sha256
    sha1sum "${file_to_check}" >> checksums.sha1
done < needs-checksum.txt
