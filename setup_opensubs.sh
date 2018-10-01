#!/bin/sh

url='http://opus.nlpl.eu/download.php?f=OpenSubtitles2018/de-en.txt.zip'
scripts=conversion_scripts

# download OpenSubtitles 2018 EN-DE
wget $url -O source.de-en.zip

# unzip XML files
unzip source.de-en.zip

# extract documents
mkdir -p documents
perl $scripts/opusXML2docs.pl --ids OpenSubtitles2018.de-en.ids --l1 en --l2 de --outdir documents --source OpenSubtitles2018.de-en.en --target OpenSubtitles2018.de-en.de

# organize into folders
for file in documents/*; do
    mkdir -p -- "${file%%_*}"
    mv -- "$file" "${file%%_*}"
done

# remove a stray document pair
rm -r documents/1191

# remove source files - uncomment if you would like to keep them
rm source.de-en.zip
rm OpenSubtitles2018.de-en.{de,en}
rm doc.order.en-de.txt
