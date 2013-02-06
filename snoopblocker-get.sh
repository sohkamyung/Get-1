#! /usr/bin/bash

### script to get image files
### should be run in the directory with the config file to use

### snoopblocker base url
snoopblocker_base="https://www.snoopblocker.com/"

### snoopblocker request string
snoopblocker_request="index.php?q="

### snoopblocker cookie request
snoopblocker_cookie_1="flags=1b2"

### gallery output file
gallery_file="gallery.html"

### regex for matching a image url
regex_image_url="https://www.snoopblocker.com/index.php?q=http%3A%2F%2Fwww.jjgirls.com%2F[0-9a-zA-Z%-]*.jpg"

### image link output file
image_file="link.html"

### regex for matching a jpg
regex_image_file_1="https://www.snoopblocker.com/index.php?q=http%3A%2F%2Fwww.jjgirls.com%2F[0-9a-zA-Z%-]*%2Frace-queens%2F[0-9]*%2Frace-queens-[0-9]*.jpg"
regex_image_file_2="https://www.snoopblocker.com/index.php?q=http%3A%2F%2F[0-9.]*%2F[0-9a-zA-Z%.-]*%2Fkeystamp%3D[0-9a-zA-Z%_-]*.jpg"
regex_image_file_3="https://www.snoopblocker.com/index.php?q=http%3A%2F%2F[0-9a-zA-Z%.-]*%26amp%3B[0-9a-zA-Z%_-]*.jpg"

### sed script for converting '%2F' to '/'
sed_replace_2F="s|%2F|/|g"
sed_replace_3D="s|%3D|/|g"

### source the config file
source ./config

#echo ${base_url}
#echo ${gallery_index}

### use getopts get command line options (will override options in config file)
OPTIONS=$(getopt -o h -l "url:,index:,continue" -n $0 -- "$@")
#echo options: ${OPTIONS}

continue=0

eval set -- "${OPTIONS}"
while true
do
    arg=$1
    shift

    case "${arg}" in
	-h)
	    echo "Usage $0:"
	    echo "    --url=\"<base gallery url>\""
	    echo "    --index=<gallery index>"
	    echo "    --continue [re-use current gallery index]"
	    exit 0
	    ;;
	--url)
	    base_url=$1
	    shift
	    ;;
	--index)
	    gallery_index=$1
	    shift
	    ;;
	--continue)
	    continue=1
	    ;;
	--)
	    break
	    ;;
	*)
	    echo "Error"
	    exit 1
	    ;;
    esac
done

### basic checks
if [ "x${base_url}" == "x" ]
then
    echo "base_url not found in the config file or via the command line"
    exit 1
fi
if [ "x${gallery_index}" == "x" ]
then
    echo "gallery_index not found in the config file or via the command line"
    exit 1
fi

if [ "x${continue}" == "x1" ]
then
    echo "Re-using current gallery file"
else
    ### get the gallery url
    echo "Getting ${base_url}${gallery_index}/"

    ### build the curl string
    curl_request="${snoopblocker_base}${snoopblocker_request}${base_url}${gallery_index}/"
    #echo ${curl_request}

    ### send the request, save the output
    #echo curl --insecure --cookie "${snoopblocker_cookie_1}" ${curl_request} -o ${gallery_file}
    curl --insecure --cookie "${snoopblocker_cookie_1}" ${curl_request} -o ${gallery_file}
fi

### extract out the image urls from the output
base_image_name=$(basename ${base_url})
gallery_list=$(grep --only-matching "${regex_image_url}" ${gallery_file} | grep "%2F${base_image_name}-[0-9]*.jpg" )
#echo ${gallery_list}

### get and store the images
for image_link in ${gallery_list}
do
    ### generate the target name from the link
    filename=$( basename $( echo ${image_link} | sed -e "${sed_replace_2F}" ) )
    # echo ${filename}
    file_number=$(echo ${filename} | grep --only-matching "[0-9]*")
    # echo ${file_number}
    output_filename=$(printf "%s-%03d-%02d.jpg" ${base_image_name} ${gallery_index} ${file_number})
    # echo ${output_filename}

    if [ -e "${output_filename}" ]
    then
	echo "File ${output_filename} exists; skipping"
    else
	touch ${output_filename}
	echo "getting ${image_link}"
	curl --insecure --cookie "${snoopblocker_cookie_1}" ${image_link} -o ${output_filename}
    fi
done
