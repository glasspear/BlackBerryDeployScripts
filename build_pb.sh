#! /bin/sh
set -e
#TODO: version shouldn't be written until a successful sign occurs, how to check?
#TODO: how to handle local vs. remote deploy 
#
#arguments

name=$1 #filename

#Action could be
# debug
# sign_debug
# sign
action=$2

## Customize all these items for your env.
# Playbook details
ip="device ip"
password="yourpassword"
signpassword="yoursigningpassword"

# path for libraries
pathtobbwp="/Developer/SDKs/Research In Motion/BlackBerry WebWorks SDK for TabletOS 2.2.0.5/bbwp"
pathtobin="$pathtobbwp/blackberry-tablet-sdk/bin"
pathtoapp="/Users/rory/Sites/$1/pb" #this is the source folder for your app
pathtobuild="/Users/rory/Sites/builds/$1/pb" # This is the directory where your app will be built to
verfile="$pathtobuild/ver.txt"

## End of things to customize ##

#functions
function getBuildId(){
    if [ -e "$verfile" ]; then
        echo "$verfile exists"
        while read line
        do
            ver=$line
        done < "$verfile"
        ver=$(( $ver + 1 ))
        echo $ver > $verfile
    else
        echo "$verfile does not exist, creating"
        ver=1
        echo $ver > $verfile
    fi 
}


if [ ! -d "$pathtobbwp" ]; then
 echo "$pathtobbwp doesn't exist."
 exit 1
fi

if [ ! -d "$pathtobin" ]; then
 echo "$pathtobin doesn't exist."
 exit 1
fi

if [ ! -d "$pathtoapp" ]; then
 echo "$pathtoapp doesn't exist."
 exit 1
fi

if [ ! -d "$pathtobuild" ]; then
 echo "$pathtobuild doesn't exist"
 exit 1
fi

# Clean up things
if [ -d "$pathtobuild/src" ]; then
 echo "removing source files"
 rm -rf $pathtobuild/src
fi

if [ -e "$pathtobuild/$name.zip" ]; then
 echo "removing $name.zip"
 rm "$pathtobuild/$name.zip"
fi

if [ -e "$pathtobuild/${name}debug.zip" ]; then
 echo "removing ${name}debug.zip"
 rm "$pathtobuild/${name}debug.zip"
fi

if [ -e "$pathtobuild/$name.bar" ]; then
 echo "removing $name.bar"
 rm "$pathtobuild/$name.bar"
fi

if [ -e "$pathtobuild/${name}debug.bar" ]; then
 echo "removing ${name}debug.bar"
 rm "$pathtobuild/${name}debug.bar"
fi

if [ ! -d "$pathtobuild/src" ]; then
 echo "Creating $pathtobuild/src"
 mkdir "$pathtobuild/src"
fi

cp -r $pathtoapp/* $pathtobuild/src

cd $pathtobuild/src
find . -name .DS_Store -delete
rm -rf nbproject

# Create a zip
zip -r $name.zip *
mv $name.zip $pathtobuild

# Compile the ZIP to a bar
cd "$pathtobbwp"

if [ "$action" == "debug" ]; then
 echo "compiling for debug"
 mv "$pathtobuild/$name.zip" "$pathtobuild/${name}debug.zip"
 if [ -e $pathtobuild/${name}debug.zip ]; then
  echo "Archive $pathtobuild/${name}debug.zip exists, starting build"
  ./bbwp "$pathtobuild/${name}debug.zip" -o "$pathtobuild" -d
  cd "$pathtobin"
  echo "deploying app to device"
  ./blackberry-deploy -installApp -password $password -device $ip -package "$pathtobuild/${name}debug.bar"
 else
  echo "Archive $pathtobuild/${name}debug.zip does not exist"
 fi
elif [ "$action" == "sign_debug" ]; then
 echo "compiling for sign and debug"
 mv "$pathtobuild/$name.zip" "$pathtobuild/${name}debugsigned.zip"
 if [ -e $pathtobuild/${name}debugsigned.zip ]; then
  echo "Archive $pathtobuild/${name}debugsigned.zip exists, starting build"
  echo "Getting buildID"
  getBuildId
  ./bbwp "$pathtobuild/${name}debugsigned.zip" -o "$pathtobuild" -d -g $signpassword -buildId $ver
  cd "$pathtobin"
  echo "deploying app to device"
  ./blackberry-deploy -installApp -password $password -device $ip -package "$pathtobuild/${name}debugsigned.bar"
 else
  echo "Archive $pathtobuild/${name}debugsigned.zip does not exist"
 fi 
elif [ "$action" == "sign" ]; then
 echo "compile for signing"

 if [ -e $pathtobuild/${name}.zip ]; then
  echo "Archive $pathtobuild/${name}.zip exists, starting build"
  echo "Getting buildID"
  getBuildId
  ./bbwp "$pathtobuild/${name}.zip" -o "$pathtobuild" -g $signpassword -buildId $ver
  cd "$pathtobin"
  echo "deploying app to device"
  ./blackberry-deploy -installApp -password $password -device $ip -package "$pathtobuild/${name}.bar"
 else
  echo "Archive $pathtobuild/${name}.zip does not exist"
 fi
else
 echo "action ($action) not found. Aborting"
fi