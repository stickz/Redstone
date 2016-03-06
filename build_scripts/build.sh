#!/usr/bin/env sh

# Once any command returns non-zero code - exit with that code
set -e

# set command line switches defaults
verbose=false
sourcemod_version="1.7.3-5255"
sourcemod_major_minor_version=0
sourcemod_major_minor_patch_version=0
sourcemod_build=0
cache=true

# process command line switches
while [ $# -gt 0 ]
do
  case "$1" in
    -v)  verbose=true;;
    --sourcemod) sourcemod_version="$2"; shift;;
    --no-cache) cache=false;;
    --)  shift; break;;
    -*)
      echo >&2 "usage: $0 [-v] [--sourcemod version-build] [--no-cache]"
      exit 1;;
    *)  break;; # terminate while loop
    esac
    shift
done

# Break down SourceMod version and trigger an error if
# provided version doesn't follow format of X.X.X-XXXX
sourcemod_major_minor_version=${sourcemod_version%.*}
sourcemod_major_minor_patch_version=${sourcemod_version%-*}
sourcemod_build=${sourcemod_version##*-}
if [ "$sourcemod_major_minor_version" = 0 ] \
  || [ "$sourcemod_major_minor_patch_version" = 0 ] \
  || [ "$sourcemod_build" = 0 ]; then
  echo "Error: Wrong SourceMod version provided: $sourcemod_version"
  echo "Error: Please provide version similar to following format: 1.7.3-5301"
  exit 1;
fi

# Detect OS and exit if OS is not supported
OS="`uname`"
case $OS in
  'Linux')
    OS='Linux'
    if [ "$verbose" = true ]; then
      echo "- Detected Linux"
    fi
    ;;
  'Darwin') 
    OS='Mac'
    if [ "$verbose" = true ]; then
      echo "- Detected OS X"
    fi
    ;;
  *)
    echo "Only Linux and OS X are supported"
    exit 1
    ;;
esac

# Get directory path of this script
if [ "$OS" = "Mac" ]; then
  SCRIPTDIR=$(cd "$(dirname "$0")"; pwd)
elif [ "$OS" = "Linux" ]; then
  SCRIPTPATH=$(readlink -f "$0")
  SCRIPTDIR=$(dirname "$SCRIPTPATH")
fi

# Get project ROOT directory
ROOTDIR=$(dirname "$SCRIPTDIR")

if [ "$verbose" = true ]; then
  echo "- Absolute project root path is $ROOTDIR"
fi

# Used for internal usage (e.g. backing up stuff, downloading sourcemod tarball
# etc.)
TMPDIR="$ROOTDIR/.tmp"

PLUGINS_SRC_BACKUP_DIR="$TMPDIR/addons_backup"
PLUGINS_SRC_DIR="$ROOTDIR/addons/sourcemod/scripting"
PLUGINS_DIST_DIR="$ROOTDIR/updater"

COMPILE_BINARY="$PLUGINS_SRC_DIR/spcomp"
COMPILE_INCLUDE_DIR="$PLUGINS_SRC_DIR/include"

SOURCEMOD_DIR="$TMPDIR/sourcemod/$sourcemod_version"
if [ "$OS" = "Mac" ]; then
  SOURCEMOD_ARCHIVE_URL="http://www.sourcemod.net/smdrop/$sourcemod_major_minor_version/sourcemod-$sourcemod_major_minor_patch_version-git$sourcemod_build-mac.zip"
  SOURCEMOD_ARCHIVE_PATH="$SOURCEMOD_DIR/archive.zip"
elif [ "$OS" = "Linux" ]; then
  SOURCEMOD_ARCHIVE_URL="http://www.sourcemod.net/smdrop/$sourcemod_major_minor_version/sourcemod-$sourcemod_major_minor_patch_version-git$sourcemod_build-linux.tar.gz"
  SOURCEMOD_ARCHIVE_PATH="$SOURCEMOD_DIR/archive.tar.gz"
fi

UPDATER_PATCH_URL="https://bitbucket.org/GoD_Tony/updater/raw/53ebb3e27e5a43bc46dc52dc0de76ac2fb48cd9e/include/updater.inc -O include/updater.inc"
UPDATER_PATCH_PATH="$TMPDIR/updater.inc"

# get list of all plugins to compile
plugins_paths=`ls ${PLUGINS_SRC_DIR}/*.sp`

# backup addons directory
if [ ! -d "$PLUGINS_SRC_BACKUP_DIR" ]; then
  mkdir -p $PLUGINS_SRC_BACKUP_DIR
fi
cp -r "$ROOTDIR/addons" "$PLUGINS_SRC_BACKUP_DIR"
if [ "$verbose" = true ]; then
  echo "- Back up /addons directory before messing it up"
fi

# download latest sourcemod and copy addons contents
if [ ! -d "$SOURCEMOD_DIR" ] || [ "$cache" = false ]; then
  if [ "$verbose" = true ]; then
    echo "- Downloading SourceMod v$sourcemod_version from
    $SOURCEMOD_ARCHIVE_URL to $SOURCEMOD_DIR"
  fi
  mkdir -p $SOURCEMOD_DIR
  wget $SOURCEMOD_ARCHIVE_URL -O $SOURCEMOD_ARCHIVE_PATH
  if [ "$OS" = "Mac" ]; then
    # -o stands for OVERWRITE, meaning don't prompt if overwriting files
    unzip -o $SOURCEMOD_ARCHIVE_PATH -d $SOURCEMOD_DIR > /dev/null
  elif [ "$OS" = "Linux" ]; then
    tar xzf $SOURCEMOD_ARCHIVE_PATH -C $SOURCEMOD_DIR
  fi
  rm -f $SOURCEMOD_ARCHIVE_PATH
else
  if [ "$verbose" = true ]; then
    echo "- Using previously downloaded SourceMod v$sourcemod_version in $SOURCEMOD_DIR"
  fi
fi

# copy SDK for successful compile
cp -r $SOURCEMOD_DIR/addons $ROOTDIR

# download latest updater patch
if [ ! -e "$UPDATER_PATCH_PATH" ] || [ "$cache" = false ]; then
  if [ "$verbose" = true ]; then
    echo "- Downloading updater patch from $UPDATER_PATCH_URL"
  fi
  wget $UPDATER_PATCH_URL -O $UPDATER_PATCH_PATH
else
  if [ "$verbose" = true ]; then
    echo "- Using previously downloaded updater patch"
  fi
fi

# Patch SourceMod updater
cp $UPDATER_PATCH_PATH $PLUGINS_SRC_DIR/include/updater.inc

# Compile
for plugin_path in $plugins_paths
do
  plugin_filename="${plugin_path##*/}"
  plugin_name="${plugin_filename%.*}"
  plugin_dir="$PLUGINS_DIST_DIR/$plugin_name/plugins"
  plugin_dest_path="$plugin_dir/$plugin_name"
  if [ ! -d "$plugin_dir" ]; then
    mkdir -p $plugin_dir
  fi
  if [ "$verbose" = true ]; then
    echo "- Compiling plugin '$plugin_name'"
  fi
  $COMPILE_BINARY $plugin_path \
    -i${COMPILE_INCLUDE_DIR} \
    -o${plugin_dest_path}
done

# restore previously backed up addons directory
rm -fr $ROOTDIR/addons
mv $PLUGINS_SRC_BACKUP_DIR/addons $ROOTDIR/addons
rm -fr $PLUGINS_SRC_BACKUP_DIR
