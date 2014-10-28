#!/bin/bash

FOLDER=`pwd`

echo
echo -e "Check directory: \e[1m"$FOLDER"\e[0m"
for dir in `ls -l $FOLDER | grep '^d' | awk '{print $9}'`
do
   echo
   echo -e "\e[41m\e[33m==========================  "$dir"  ======================\e[49m\e[39m"
   cd $FOLDER/$dir
   GITREMOTE=`git remote show`
   # Command for update information 
   git branch --set-upstream-to=$GITREMOTE/master
   echo
   git fetch $GITREMOTE
   echo -e "--- \e[32mSTATUS\e[39m ---"
   git status
   echo
   echo -e "---  \e[32mDIFF\e[39m  ---"
   # Diff between branch local and remote
   git diff master $GITREMOTE/master
done
