#!/bin/bash

# COLORS
NOCOLOR="\033[0m"
LIGHTRED="\033[0;31m"
LIGHTGREEN="\033[0;32m"
LIGHTYELLOW="\033[0;33m"
LIGHTPURPLE="\033[0;34m"
LIGHTPINK="\033[0;35m"
LIGHTCYAN="\033[0;36m"
LIGHTWHITE="\033[0;37m"
DARKGRAY="\033[1;30m"
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
PURPLE="\033[1;34m"
PINK="\033[1;35m"
CYAN="\033[1;36m"
WHITE="\033[1;37m"

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PATHFILE="${SCRIPTDIR}/hostspath.conf"
PATHPROFILEFOLDER="${SCRIPTDIR}/profiles"
TEMPHOST="${SCRIPTDIR}/temphost.temp"
PROFILES=()
HOSTSPATH=""
TEMPLATEMARK="### --- ALL LINES ABOVE ARE CREATED BY H-MANAGER.sh --- ###"

function isRoot(){
if [[ "$EUID" -ne 0 ]]
then 
    message "Please run as root" "error"
    exit
fi
}

function header(){
    message "**********************" "header"
    message "* H-Manager v: 0.0.0 *" "header"
    message "**********************" "header"
    message
}

function message(){
    color=""
    case $2 in
        header)
            color=$PURPLE
        ;;
        error)
            color=$RED
        ;;
        warning)
            color=$LIGHTYELLOW
        ;;
        input)
            color=$LIGHTCYAN
        ;;
        important)
            color=$GREEN
        ;;
        *)
            color=$LIGHTWHITE
        ;;
    esac

    echo -e "${color}$1${LIGHTWHITE}"
}

function fileExists(){
    local FILE=$1
    if test -f "$FILE"; then
        return 1
    fi
    return 0
}

function dirExists(){
    local DIR=$1
    if test -d "$DIR"; then
        return 1
    fi
    return 0
}

function askForPath(){

    message "type your hosts file path (eg.: /etc/hosts):" "input"
    read res

    if [[ $res == "" ]]
    then 
        res="/etc/hosts"
        message "assuming $res" "warning"
    fi

    fileExists $res
    if [ $? == 0 ]
    then
        message "informed file does not exist" "error"
        message "informed file: $res" "error"
        exit
    else
        writeLastPath $res
    fi

}

function writeLastPath(){
    HOSTSPATH=$1
    echo $HOSTSPATH > $PATHFILE
}

function readLastPathFile(){
    while read line; do
        local content=$line
        break
    done < $1

    HOSTSPATH=$content
}

function checkHostsFile(){
    local res
    fileExists $HOSTSPATH
    if [ $? != 0 ]
    then
        message "applying on $HOSTSPATH" "warning"
        message "([c]ontinue/chan[g]e)" "input"
        read res
    else
        message "Error: can not found hosts file: $HOSTSPATH" "error"
        exit
    fi

    if [[ $res == "g" ]]
    then
        askForPath
    fi

}

function checkTemplateExists(){
    local i=1
    local found=0
       
    message $HOSTSPATH
    while read line; do
        if [[ $line == $TEMPLATEMARK ]]
        then
            found=1
            break
        fi
        i=$((i+1)) 
    done < $HOSTSPATH

    if [ $found == 0 ]
    then

        message "Template not found. Adding at end of file" "warning"
        echo $TEMPLATEMARK >> $HOSTSPATH
        return $((i+1)) 
    else
        message "Template found" "input"
        return $i    
    fi   

}

function showOptions(){
    local res
    clear
    header
    message "What you want to do? [${HOSTSPATH}]" "important"
    message
    message "RESET - erase all hosts added by H-Manager" "warning"
    message "PROFILE - load a profile or create a new one" "warning"
    message "EDIT - simple edit the hosts file" "warning"
    message
    message "([r]eset/[p]rofile/[e]dit)" "input"
    
    read res
    local R=${res^^}
    case ${R:0:1} in
        R)
            resetChanges
            exit
        ;;
        P)
            loadSaveProfile
            exit
        ;;
        E)
            "${EDITOR:-vi}" $HOSTSPATH
            exit
        ;;
        *)
            message "Invalid option..." "error"
            exit
        ;;
    esac
}

function loadSaveProfile(){
    local res
    clear
    header
    message "What you want to do? [${HOSTSPATH}]" "important"
    message
    message "LOAD - load a profile from the profiles folder" "warning"
    message "SAVE - create a new profile based from your actual $HOSTSPATH" "warning"
    message "([l]oad/[s]ave)" "input"
    
    read res
    local R=${res^^}
    case ${R:0:1} in
        L)
            loadProfile
            exit
        ;;
        S)
            saveProfile
            exit
        ;;
        *)
            message "Invalid option..." "error"
            exit
        ;;
    esac 
}

function sanitizeProfileFolder(){
    dirExists $PATHPROFILEFOLDER
    if [[ $? == 0 ]]
    then 
        install -d -o $SUDO_USER $PATHPROFILEFOLDER 
    fi

    for entry in "$PATHPROFILEFOLDER"/*.profile
    do
        if [ -f "$entry" ];then
            PROFILES+=("$entry")
        fi
    done

}

function loadProfile(){
    sanitizeProfileFolder
    local res
    clear
    header
    message "Which profile do you want to load? [${HOSTSPATH}]" "important"
    message
    for ((I=0;I<${#PROFILES[@]};I++)); do
        message "$I -- ${PROFILES[I]}" "warning"
    done

    if [ $I -lt 1 ]; then
        message "the profile folder is empty..." "error"
        exit 1
    fi

    message "(enter the number of your choice...)" "input"
    read res
    local re='^[0-9]+$'
    if ! [[ $res =~ $re && $res -lt $I ]] ; then
        message "Invalid option..." "error" >&2; exit 1
    fi

    message "loading profile -> ${PROFILES[res]} ..." "important"

    mergeFiles $HOSTSPATH ${PROFILES[res]}

}

function mergeFiles(){
    local f1=$1
    local f2=$2
    
    resetChanges
    cat $f2 >> $f1
    message "$f2 has been merged into $f1..." "important"
}

function saveProfile(){
    sanitizeProfileFolder
    echo 1
}

function resetChanges(){
    rm $TEMPHOST
    head -n $TEMPLATESTART $HOSTSPATH > $TEMPHOST
    cat $TEMPHOST > $HOSTSPATH
    message "All changes on $HOSTSPATH are removed"
}


header
#check if is sudoer
isRoot
sanitizeProfileFolder
#check if exists a last hosts path
# fileExists
fileExists $PATHFILE
if [ $? == 0 ]
then
    askForPath
fi
#ask if should edit the last hosts path
readLastPathFile $PATHFILE
checkHostsFile

#check if exists the template mark
checkTemplateExists 
TEMPLATESTART=$?

#if template mark  and something above exists, ask for reset / load profile or manual input 
showOptions

#if manual input, ask if add more / save as profile / exit
