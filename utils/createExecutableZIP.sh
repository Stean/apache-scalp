#!/bin/bash
#===============================================================================
#
#          FILE: createExecutableZIP.sh
# 
#         USAGE: ./createExecutableZIP.sh
# 
#   DESCRIPTION: This script is mainly for developers, who want to test their
#		 code local packed before commiting. It zipps the complete parent
#		 dir using the zip-command and adds a Python Shebang as first line.
# 
#       OPTIONS: -d	write final zip to this destination
#		 -f	Don't ask before overriding
#		 -h	print this help
#  REQUIREMENTS: zip
#		 mktemp
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Stean <stean@gmx.org>
#       CREATED: 27.02.2013 15:32:00 CET
#      REVISION: 0.2
#===============================================================================

ZIP_SHEBANG='#!/usr/bin/env python'
ZIP_COMMENT="This is a zip-file containing python-scripts, which are unpacked and executed by the python interpreter"
ZIP_ROOT_DIR=".."	#this script has to know where the
			#sources are (only in zip-modus)

zip_temp_filename=`mktemp -u`

#Set default settings
force_override=0
file_target_path="scalp.py"	#it should look like a normal python file
				#because you can execute it directly

#===============================================================================

print_usage ()
{
	echo "usage: $0 [Options]"
	echo ""
	echo "Options:"
	echo "-d	write final zip to this destination (default: scalp.py)"
	echo "-f	don't ask before overriding"
	echo "-h	print this help"
}


progress_params ()
{
	while [ "$1" != "" ]; do
		case $1 in
			-d)	shift
				file_target_path="$1"
				shift
				;;

			-f)	shift
				force_override=1
				;;

			-h)	print_usage
				exit 0
				;;

			*)	echo "Unknown param: $1" >&2
				print_usage
				;;
		esac
	done
}

#==============================================================================

#Check the params
progress_params "$@"

#Check if there is already a scalp.py before overwriting
if [ -f "${file_target_path}" -a $force_override -eq 0 ]; then
	echo "Override existing file \"${file_target_path}\"?"
	while true; do
		read -p "[y/n]" -n 1 result
		case $result in
			[Yy]* ) break;;	#escape loop
			[Nn]* ) exit;;	#exit script
		esac
		echo	#newline
	done
	echo	#newline
fi

pushd $ZIP_ROOT_DIR > /dev/null     #Seems like the programms can't truncate the root-dir, so we need this workaround with pushd, zip/git and popd
echo "============== ZIP OUTPUT ==============" 
zip -r --exclude=*.git* $zip_temp_filename *
ret=$?
echo "========================================" 
popd > /dev/null

if [ $ret -eq 0 ]; then
	echo -en "$ZIP_SHEBANG\n#$ZIP_COMMENT\n" | cat - $zip_temp_filename > $file_target_path
	rm $zip_temp_filename
else
	echo "Something went wrong, when generating the zip file" >&2
fi

