#!/usr/bin/env sh

# set command line switches defaults
verbose=false

# process command line switches
while [ $# -gt 0 ]
do
  case "$1" in
    -v)  verbose=true;;
    --repo=*) repo=`echo $1 | sed -e 's/^[^=]*=//g'`;;
    --token=*) token=`echo $1 | sed -e 's/^[^=]*=//g'`;;
    --branch=*) branch=`echo $1 | sed -e 's/^[^=]*=//g'`;;
    --dir=*) dir=`echo $1 | sed -e 's/^[^=]*=//g'`;;
    --)  shift; break;;
    -*)
      echo >&2 "usage: $0 [-v]
                          [--repo github.com/owner/repo]
                          [--token OAuth token]
                          [--dir directory to deploy]
                          [--branch remote branch]"
      exit 1;;
    *)  break;; # terminate while loop
    esac
    shift
done

if [ -z ${repo+x} ] || [ "$repo" = "" ]; then
  echo "Error: No repo is specified. Please specify one in --repo= argument"
  exit 1
fi

if [ "$verbose" = true ]; then
  echo "- Provided repo: $repo"
fi

if [ -z ${dir+x} ] || [ "$dir" = "" ]; then
  echo "Error: No directory to deploy is specified. Please specify one in --dir= argument"
  exit 1
fi

if [ "$verbose" = true ]; then
  echo "- Provided directory: $dir"
fi

if [ -z ${token+x} ] || [ "$token" = "" ]; then
  echo "Error: No Github OAuth token is specified. Please specify one in --token= argument"
  exit 1
fi

if [ -z ${branch+x} ] || [ "$branch" = "" ]; then
  echo "Error: No branch is specified. Please specified one in --branch= argument"
  exit 1
fi

if [ "$verbose" = true ]; then
  echo "- Provided branch: $branch"
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

BUILDDIR="$ROOTDIR/$dir"

cd $BUILDDIR
git init
git config user.name "Travis-CI"
git config user.email "travis@example.com"
git add .
git commit -m "Build Redstone server"
git push --force --quiet "https://${token}@${repo}" master:${branch} > /dev/null 2>&1
rm -fr .git

if [ "$verbose" = true ]; then
  echo "- Deployed $dir to branch $branch on $repo"
fi
