#!/bin/bash

set -e

url='http://opus.nlpl.eu/download.php?f=OpenSubtitles2018/de-en.txt.zip'
scripts=conversion_scripts

echo "| Downloading and unzipping corpus..."

# download OpenSubtitles 2018 EN-DE and unzip
if [ `ls OpenSubtitles.* 2> /dev/null | wc -l` == 3 ]; then
    echo "| - OpenSubtitles seems to be downloaded and unzipped already. To repeat download, remove one of  ['OpenSubtitles.de-en.ids', 'OpenSubtitles.de-en.en', 'OpenSubtitles.de-en.de']."
else
    wget $url -O source.de-en.zip
    unzip -o source.de-en.zip
fi

echo "| Extracting documents from XML files..."

# extract documents
if [ ! -d documents ]; then
    mkdir documents
    perl $scripts/opusXML2docs.pl --ids OpenSubtitles.de-en.ids --l1 en --l2 de --outdir documents --source OpenSubtitles.de-en.en --target OpenSubtitles.de-en.de
else
    echo "| - Documents seem to be extracted already. To repeat extraction, remove the folder 'documents'."
fi

echo "| Organize into folders by year and clean up..."

# organize into folders
if [ ! -d documents/1916 ]; then
    for file in documents/*; do
        mkdir -p -- "${file%%_*}"
        mv -- "$file" "${file%%_*}"
    done
else
    echo "| - Documents seem to be organized by year already. To repeat, remove all subfolders documents/*"
fi

# remove a stray document pair
rm -rf documents/1191

# remove source files - comment out if you would like to keep them
rm -f source.de-en.zip
rm -f OpenSubtitles.de-en.{de,en,ids}
rm -f doc.order.en-de.txt
rm -f README
