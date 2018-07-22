#!/usr/bin/env sh

# Once any command returns non-zero code - exit with that code
set -e

# set command line switches defaults
verbose=false
sourcemod_version="1.7.3-5294"
cache=true

# process command line switches
while [ $# -gt 0 ]
do
  case "$1" in
    -v)  verbose=true;;
    --sourcemod=*) sourcemod_version=`echo $1 | sed -e 's/^[^=]*=//g'`;;
    --no-cache) cache=false;;
    --out=*) output_dir=`echo $1 | sed -e 's/^[^=]*=//g'`;;
    --)  shift; break;;
    -*)
      echo >&2 "usage: $0 [-v] [--sourcemod=version-build] [--no-cache]"
      exit 1;;
    *)  break;; # terminate while loop
    esac
    shift
done

# Break down SourceMod version
sourcemod_major_minor_version=${sourcemod_version%.*}
sourcemod_major_minor_patch_version=${sourcemod_version%-*}
sourcemod_build=${sourcemod_version##*-}

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

# If --out= is passed and path is absolute - set as is,
# if path is relative - append to project root directory
# if --out= is not passed, use default path
if [ -n ${output_dir+x} ] && [ "$output_dir" != "" ]; then
  if [ "${output_dir%${output_dir#?}}"x = '/x' ]; then
    BUILDDIR="$output_dir"
  else
    BUILDDIR="$ROOTDIR/$output_dir"
  fi
else
  BUILDDIR="$ROOTDIR/build"
fi

PLUGINS_SRC_BACKUP_DIR="$TMPDIR/addons_backup"
PLUGINS_SRC_DIR="$ROOTDIR/addons/sourcemod/scripting"
PLUGINS_DIR="$ROOTDIR/updater"
PLUGINS_DIST_DIR="$BUILDDIR/updater"

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

############
# Action!
##########

# Reset build directory
rm -fr $BUILDDIR && mkdir $BUILDDIR

# Prepare directory where we place compiled plugins
mkdir $PLUGINS_DIST_DIR

# get list of all plugins to compile
plugins_paths=`ls ${PLUGINS_SRC_DIR}/*.sp`

# backup addons directory
rm -fr $PLUGINS_SRC_BACKUP_DIR
mkdir -p $PLUGINS_SRC_BACKUP_DIR
cp -r "$ROOTDIR/addons" "$PLUGINS_SRC_BACKUP_DIR"
if [ "$verbose" = true ]; then
  echo "- Back up /addons directory before messing it up"
fi

# download latest sourcemod and copy addons contents
if [ ! -d "$SOURCEMOD_DIR" ] || [ "$cache" = false ]; then

  # check that SourceMod file URL is correct
  wget --spider $SOURCEMOD_ARCHIVE_URL
  if [ $? -ne 0 ]; then
    echo "Error: could not download SourceMod v$sourcemod_version"
    echo "Error: Please make sure to provide existing version in following format: 1.7.3-5301"
    exit 1;
  fi

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
  plugin_dir="$PLUGINS_DIST_DIR/$plugin_name"
  plugin_translations_dir="$PLUGINS_DIR/$plugin_name/translations"
  plugin_dest_path="$plugin_dir/plugins/$plugin_name"
  plugin_updater_path="$plugin_dir/$plugin_name.txt"

  if [ ! -d "$plugin_dir/plugins" ]; then
    mkdir -p $plugin_dir/plugins
  fi

  # Copy translations
  if [ -d "$plugin_translations_dir" ]; then
    if [ "$verbose" = true ]; then
      echo "- Copying plugin '$plugin_name' translations"
    fi
    cp -r $plugin_translations_dir $plugin_dir
  fi

  # get plugin's last commit and extract 7 characters hash off of it
  plugin_paths_for_hash="$plugin_path"
  if [ -d "$plugin_translations_dir" ]; then
    plugin_paths_for_hash="$plugin_paths_for_hash $plugin_translations_dir"
  fi
  plugin_hash=`git log -n 1 --oneline -- ${plugin_paths_for_hash}`
  plugin_hash=`echo $plugin_hash | sed -e 's/\s.*$//g'`

  sed "s/version\s*=\s*[^,]*/version = \"${plugin_hash}\"/g" $plugin_path > $TMPDIR/${plugin_name}
  mv $TMPDIR/${plugin_name} ${plugin_path}
  if [ "$verbose" = true ]; then
    echo "- Replaced version in $plugin_name.sp with hash $plugin_hash"
  fi

  if [ "$verbose" = true ]; then
    echo "- Compiling plugin '$plugin_name'"
  fi
  $COMPILE_BINARY $plugin_path \
    -i${COMPILE_INCLUDE_DIR} \
    -o${plugin_dest_path}

  # Add updater file with a directory in /updater
    echo '"Updater" {' >> $plugin_updater_path
    echo '  "Information" {' >> $plugin_updater_path
    echo '    "Version" {' >> $plugin_updater_path
    echo "      \"Latest\" \"$plugin_hash\"" >> $plugin_updater_path
    echo '    }' >> $plugin_updater_path
    echo '  }' >> $plugin_updater_path
    echo '  "Files" {' >> $plugin_updater_path
    # turn off variable value expansion except for splitting at newlines
    set -f; IFS='
    ' 
    for line in `find $plugin_dir -type f -not -path $plugin_updater_path`; do
      set +f; unset IFS
      file_relative_path=`echo $line | sed -e "s|${plugin_dir}||g"`
      echo "    \"Plugin\" \"Path_SM$file_relative_path\"" >> $plugin_updater_path
    done
    set +f; unset IFS
    echo '  }' >> $plugin_updater_path
    echo '}' >> $plugin_updater_path
    if [ "$verbose" = true ]; then
      echo "- Generated Updater file for plugin '$plugin_name'"
    fi
done

# restore previously backed up addons directory
rm -fr $ROOTDIR/addons
mv $PLUGINS_SRC_BACKUP_DIR/addons $ROOTDIR/addons
rm -fr $PLUGINS_SRC_BACKUP_DIR
