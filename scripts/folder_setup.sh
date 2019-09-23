#!/bin/bash
# Script to create gkoerk's famously awesome folder structure for stacks

# Set folder paths here (you should not need to change these, but if you do, it will save a load of typing)
appdata=/share/appdata
config=/share/appdata/config
runtime=/share/runtime


# Help message for script
helpFunction()
{
   echo ""
   echo "Usage: $0 -f <folder name>"
   echo -f "-f name of folder(s) you wish to add. For more than one folder, use -f <folder name 1> <folder name 2> ... <foldernme 9>. You can have 9 folder names in a single command"
   exit 1 # Exit script after printing help
}


# Print helpFunction in case parameters are empty
if [ -z "$1" ]
then
   echo "Please enter at least one folder name";
   helpFunction
fi

# Create folder structure

mkdir -p $appdata/{$1,$2,$3,$4,$5,$6,$7,$8,$9}
mkdir -p $config/{$1,$2,$3,$4,$5,$6,$7,$8,$9}
mkdir -p $runtime/{$1,$2,$3,$4,$5,$6,$7,$8,$9}

echo "The following folders were setup:"
echo " - $@"

