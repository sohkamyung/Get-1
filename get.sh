#! /usr/bin/bash

### script to get image files
### should be run in the directory with the config file to use

### array of hidemyass urls

hidemyass_array[0]="https://1.hidemyass.com/"
hidemyass_array[0]="https://2.hidemyass.com/"
hidemyass_array[0]="https://3.hidemyass.com/"
hidemyass_array[1]="https://4.hidemyass.com/"
hidemyass_array[2]="https://5.hidemyass.com/"
hidemyass_array[3]="https://6.hidemyass.com/"
hidemyass_array[4]="https://7.hidemyass.com/"
num_elements=7

### randomly choose one to use
while true
do
    (( index = $RANDOM % ${num_elements} ))
    hidemyass_base=${hidemyass_array[${index}]}
    if [ "x${hidemyass_base}" != "x" ]
    then
	echo "Using ${hidemyass_base} to get data"
	break
    fi
done

### hidemyass base url
### hidemyass_base="https://5.hidemyass.com/"

### hidemyass request string
hidemyass_request="ip-1/encoded/"

### gallery output file
gallery_file="gallery.html"

### regex for matching a encoded url
regex_encoded_url="/encoded/[0-9a-zA-Z%]*"
regex_encoded_url1="/encoded/"
regex_encoded_url2="[0-9a-zA-Z%]*"

### regex for matching a image url
regex_image_url="http://www.jjgirls.com/[0-9a-zA-Z/-]*.jpg"

### sed script for converting '%3D' to '='
sed_replace_3D="s|%3D|=|g"

### source the config file
source ./config

#echo ${base_url}
#echo ${base_url} | cut -b 5-
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

### encode the gallery_url - use later for grep matching
encoded_gallery_url=$(echo ${base_url} | cut -b 5- | base64 -w 0 | cut -b -36)
#echo ${encoded_gallery_url}

if [ "x${continue}" == "x1" ]
then
    echo "Re-using current gallery file"
else
    ### get the gallery url
    echo "Getting ${base_url}${gallery_index}/"

    ### truncate the url prior first
    truncated_url=$(echo "${base_url}${gallery_index}/" | cut -b 5-)
    #echo ${truncated_url}

    ### base64 encode the url
    encoded_url=$(echo ${truncated_url} | base64)
    #echo ${encoded_url}

    ### build the curl string
    curl_request="${hidemyass_base}${hidemyass_request}${encoded_url}"
    #echo ${curl_request}

    ### send the request, save the output
    #echo curl --insecure --cookie "${snoopblocker_cookie_1}" ${curl_request} -o ${gallery_file}
    curl --insecure ${curl_request} -o ${gallery_file}
fi

### extract out all the encoded urls from the file
### add in the encoded gallery url to filter for gallery related urls only
#encoded_urls=$(grep --only-matching "${regex_encoded_url}" ${gallery_file} | sed "${sed_replace_3D}" | cut -b 10-)

encoded_urls=$(grep --only-matching "${regex_encoded_url1}${encoded_gallery_url}${regex_encoded_url2}" ${gallery_file} | sed "${sed_replace_3D}" | cut -b 10-)
#echo ${encoded_urls}
#echo ${regex_encoded_url1}${encoded_gallery_url}${regex_encoded_url2}
#echo ${base_url}

base_image_name=$(basename ${base_url})
#echo ${base_image_name}

(( i=0 ))
for encoded_url in ${encoded_urls}
do
    ### convert to conventional url
    unencoded_url="http$(echo ${encoded_url} | base64 -d)"

    ### find the required images
    image_link=$(echo "${unencoded_url}" | grep --only-matching "${regex_image_url}" | grep "/${base_image_name}-[0-9]*.jpg")
    if [ "x${image_link}" != "x" ]
    then
	#echo "=====> ${image_link}"
        ### generate the target name from the link
	filename=$( basename $( echo ${image_link} ) )
        #echo ${filename}
	file_number=$(echo ${filename} | grep --only-matching "[0-9]*")
        #echo ${file_number}
	output_filename=$(printf "%s-%03d-%02d.jpg" ${base_image_name} ${gallery_index} ${file_number})
        #echo ${output_filename}

	get_file=1
	if [ -e "${output_filename}" ]
	then
	    ### check that the image is ok
	    info=$(identify -regard-warnings ${output_filename} &> /dev/null)
	    if [ $? -eq 0 ]
	    then
		echo "File ${output_filename} exist and is good - skipping"
		get_file=0
	    fi
	fi
	if [ ${get_file} -eq 1 ]
	then
	    touch ${output_filename}
    	    ### reconvert the target name to an encoded url
	    ### have to remove the inital 'http:'
	    curl_request="${hidemyass_base}${hidemyass_request}$(echo ${image_link} | cut -b 5- | base64 -w 0)"
	    #echo ${curl_request}
	    ### get the file
	    echo "getting ${image_link}"
	    curl --insecure ${curl_request} -o ${output_filename}
	fi
	(( i++ ))
    fi
done

if [ "${i}" -ne "12" ]
then
    echo "Warning: did not find 12 image files"
fi
