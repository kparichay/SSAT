#!/usr/bin/env bash
##
# @file ssat.sh
# @author MyungJoo Ham <myungjoo.ham@gmail.com>
# @date Jun 22 2018
# @license Apache-2.0
# @brief This executes test groups and reports aggregated test results.
# @exit 0 if all PASSED. Positive if some FAILED.
# @dependency sed
#
# If there is no arguments specified, this will search for all "runTest.sh" in
# the subdirectory of this file and regard them as the test groups.
#
# If a testgroup (runTest.sh) returns 0 while there are failed testcase,
# it implies that the failed testcases may be ignored and it's good to go.
#
# If --help or -h is given, this will show detailed description.

TARGET=$(pwd)
BASEPATH=`dirname "$0"`
BASENAME=`basename "$0"`
TESTCASE="runTest.sh"

#
SILENT=1

# Handle arguments
POSITIONAL=()
while [[ $# -gt 0 ]]
do
	key="$1"
	case $key in
	-h|--help)
		printf "usage: ${BASENAME} [--help] [<path>] [--testcase <filename>] [--nocolor] [--showstdout]\n\n"
		printf "These are common ${Red}ssat${NC} commands used:\n\n"
		printf "Test all test-groups in the current ($(pwd)) directory, recursively\n"
		printf "    (no options specified)\n"
		printf "    $ ${BASENAME}\n"
		printf "\n"
		printf "Test all test-groups in the specified directory, recursively\n"
		printf "    <path>\n"
		printf "    $ ${BASENAME} /home/username/test\n"
		printf "    If there are multiple paths, the last one will be used\n"
		printf "\n"
		printf "Search for \"filename\" as the testcase scripts\n"
		printf "    --testcase or -t\n"
		printf "    $ ${BASENAME} --testcase cases.sh\n"
		printf "    Search for cases.sh instead of runTest.sh\n"
		printf "\n"
		printf "Do not emit colored text\n"
		printf "    --nocolor or -n\n"
		printf "\n"
		printf "Show stdout of test cases\n"
		printf "    --showstdout or -s\n"
		printf "\n"
		printf "Shows this message\n"
		printf "    --help or -h\n"
		printf "    $ ${BASENAME} --help \n"
		printf "\n\n"
		exit 0
	;;
	-n|--nocolor)
	nocolor=1
	shift
	;;
	-t|--testcase)
	TESTCASE="$2"
	shift
	shift
	;;
	-s|--showstdout)
	SILENT=0
	shift
	;;
	*) # Unknown, which is probably target (the path to root-dir of test groups).
	TARGET="$1"
	esac
done

source ${BASEPATH}/ssat-api.sh

if [[ "${#TARGET}" -eq "0" ]]
then
	TARGET="."
fi

TNtc=0
TNtcpass=0
TNtcfail=0
TNgroup=0
TNgrouppass=0
TNgroupfail=0
log=""
groupLog=""

while read -d $'\0' file
do
	CASEBASEPATH=`dirname "$file"`
	CASENAME=`basename "$CASEBASEPATH"`
	Ntc=0
	Npass=0
	Nfail=0
	tmpfile=$(mktemp)

	pushd $CASEBASEPATH > /dev/null
	output=$(. $file)
	retcode=$?
	popd > /dev/null

	logfile="${output##*$'\n'}"

	resultlog=$(<$logfile)
	effectiveOutput=`printf "$resultlog" | sed '$d'`
	log="$log$effectiveOutput\n"

	lastline=`printf "${resultlog}" | sed '$!d'`
	IFS=/
	set $lastline
	Ntc=$1
	Npass=$2
	Nfail=$3

	TNtc=$((TNtc+Ntc))
	TNtcpass=$((TNtcpass+Npass))
	TNtcfail=$((TNtcfail+Nfail))

	TNgroup=$((TNgroup+1))
	if [[ "$retcode" -eq "0" ]]
	then
		TNgrouppass=$((TNgrouppass+1))
		groupLog="${groupLog}${LightGreen}[PASSED]${NC} ${Blue}${CASENAME}${NC} ($Npass passed among $Ntc cases)\n"
	else
		TNgroupfail=$((TNgroupfail+1))
		groupLog="${groupLog}${Red}[FAILED]${NC} ${Blue}${CASENAME}${NC} ($Npass passed among $Ntc cases)\n"
	fi

done < <(find $TARGET -name $TESTCASE -print0)

printf "\n\n==================================================\n\n"

printf "$log\n"
printf "==================================================\n\n"
printf "$groupLog"
printf "==================================================\n"

if (( ${TNgroupfail} == 0 ))
then
	printf "${LightGreen}[PASSED] ${Blue}All Test Groups (${TNgroup}) Passed!${NC}\n\n"
	exit 0
else
	printf "${Red}[FAILED] ${Purple}There are failed test groups! (${TNgroupfail})${NC}\n\n"
	exit 1
fi
# gather reports & publish them.
