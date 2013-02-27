#!/bin/bash
#===============================================================================
#
#          FILE: createExecutableZIP.sh
# 
#         USAGE: ./createExecutableZIP.sh
# 
#   DESCRIPTION: This script is mainly for developers, who want to test their
#		 code local packed before commitingZipps the complete parent
#		 dir using "git archive" (zip as fallback) and adds an Python
#		 Shebang as first line. 
# 
#       OPTIONS: -d	write final zip to this destination
#		 -f	Don't ask before overriding
#		 -g	Force the use of git (quit, if git isn't installed)
#		 -h	print this help
#		 -z	Force the use of the zip-command (quit, if git isn't installed)
#  REQUIREMENTS: zip/git
#		 mktemp
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Stean <stean@gmx.org>
#       CREATED: 26.02.2013 12:06:44 CET
#      REVISION: 0.1
#===============================================================================

ZIP_SHEBANG='#!/usr/bin/env python'
ZIP_COMMENT="This is a zip-file containing python-scripts, which are unpacked and executed by the python interpreter"
ZIP_ROOT_DIR=".."	#this script has to know where the
			#sources are (only in zip-modus)

zip_temp_filename=`mktemp -u`

#Set default settings
force_override=0
force_git=0
force_zip=0
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
	echo "-g	force the use of git (quit, if git isn't installed)"
	echo "-h	print this help"
	echo "-z	force the use of the zip-command (quit, if git isn't installed)"
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

			-g)	shift
				force_git=1
				;;

			-h)	print_usage
				exit 0
				;;

			-z)	shift
				force_zip=1
				;;

			*)	echo "Unknown param: $1" >&2
				print_usage
				;;
		esac
	done

	#check for competing params
	if [ $force_git -eq 1 -a $force_zip -eq 1 ]; then
		echo "You cannot specify both, -g and -z" >&2
		exit 1
	fi

}


use_git ()
{
	git archive --format=zip -o $zip_temp_filename HEAD
}


use_zip ()
{
	zip -r --exclude=*.git* -q $zip_temp_filename *
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
fi

pushd $ZIP_ROOT_DIR > /dev/null     #Seems like the programms can't truncate the root-dir, so we need this workaround with pushd, zip/git and popd

if [ $force_git -eq 1 -o $force_zip -eq 1 ]; then
	if [ $force_git -eq 1 ]; then
		use_git;
	fi

	if [ $force_zip -eq 1 ]; then
		use_zip;
	fi
else
	use_git;
	if [ $? -ne 0 ]; then
		use_zip;
		echo "Something went wrong with git archive, trying again with zip"
	fi
fi

popd > /dev/null

if [ $? -eq 0 ]; then
	echo -en "$ZIP_SHEBANG\n#$ZIP_COMMENT\n" | cat - $zip_temp_filename > $file_target_path
	rm $zip_temp_filename
else
	echo "There was an error generating the zip file" >&2
fi

