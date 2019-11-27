#!/bin/bash

path=$1
files=$(ls $path)
suffix='.txt'
save_dir=${path}'/save_dir'
empty_try=5

usage(){
	echo "Usage: `basename $0` <path/to/your/files>"
	echo "e.g.: $0 ./test/path"
}

saveUrl(){
	mkdir $1

	for filename in $files
	do
		if echo ${path}"/"${filename} | grep '\.md' &>/dev/null;then
			file_dir=${save_dir}'/'${filename%.*}
			save_file=${file_dir}'/'${filename%.*}${suffix}
			
			grep -P -o -q '(?<=!\[\]\().*(?=\))' ${path}"/"${filename}
			if [ $? -ne 0 ];then
				true
			else
				mkdir $file_dir
				touch $save_file
				grep -P -o '(?<=!\[\]\().*(?=\))' ${path}"/"${filename} >> ${save_file}
			fi
		else
			continue
		fi
	done
}

downLoadImg(){
	row=0
	arr=$3
	#echo "arr: "$arr
	#echo $2
	echo "Downloading "${1}" ..."
	for url in $(cat $2)
	do
		let "row++"
		if echo "${arr[@]}" | grep "\b$row\b" &>/dev/null;then
			echo -n "URL-"$url
			proxychains wget --timeout 5 -O ${1}"/"${row}".png" $url 2>/dev/null
			empty_check=$(ls -s ${1}"/"${row}".png" | grep -o -P '\b0(?= )')
			if [ $? -ne 0 ];then
				echo -e "\033[32m [SUCCESS] \033[0m"
			else
				echo -e "\033[31m [FAIL] \033[0m"
			fi
		else
			continue
		fi
	done
}

checkEmpty(){
	remaining_atp=$[empty_try-1]
	echo "----------------CheckEmpty(remaining attempts:$remaining_atp)----------------------"
	cd ${1}
	pwd
	urllist=$(ls -s *.png | grep -o -P '(?<=\b0 )\w+')
	echo ${urllist[*]}
	cd -
	downLoadImg $1 $2 "${urllist[*]}"
}

if [ $# -ne 1 ];then
	usage
	exit 1
fi


if [ ! -d $save_dir ];then
	saveUrl $save_dir
	dirs=$(ls $save_dir)
	for dirname in $dirs
	do
		url_dir=${save_dir}"/"${dirname}
		urlfile=${url_dir}"/"${dirname}${suffix}
		urllist=$(seq $(wc -l $urlfile | grep -o -P '\w+(?= )'))
		downLoadImg $url_dir $urlfile "${urllist[*]}" 
		while [ ${empty_try} -ne 0 ]
		do
			empty_check=$(ls -s ${url_dir}/*.png | grep -o -P '\b0(?= )')
			if [ $? -ne 0 ];then
				echo ${dirname}" CLEAR"
				empty_try=5
				break
			else
				checkEmpty $url_dir $urlfile
				let "empty_try--"
			fi
		done
		echo -e "\033[32m"$dirname" complete \033[0m"
		empty_try=5
	done
	
else
	echo $save_dir' exist'
	exit 1
fi





