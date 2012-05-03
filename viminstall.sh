#!/bin/bash
#	Shell script to download and install Vim with the latest patches applied.
#
APPNAME=vim									# app name
APPSDIR=apps								# apps dir
BUILDDIR=build								# build directory
INSTALLPATH=$HOME/$APPSDIR/$APPNAME	# full install path
BUILDPATH=$HOME/$BUILDDIR/$APPNAME	# full build path
COMPILEDBY=TaQ								# put your name here to show it with :version
SOURCEURL=ftp://ftp.vim.org/pub/vim/unix/
PATCHESURL=ftp://ftp.vim.org/pub/vim/patches/

echo ===============================================================================
echo Viminstall 
echo Find, download, extract, configure and install the latest Vim version.
echo Check for the latest version of this script on http://github.com/taq/viminstall
echo ===============================================================================

# check for some tools needed
LYNXCHECK=$(which lynx)
if [ -z "$LYNXCHECK" ]; then
	echo I need lynx to work, but you dont have it installed.
	exit 1
fi

WGETCHECK=$(which wget)
if [ -z "$WGETCHECK" ]; then
	echo I need wget to work, but you dont have it installed.
	exit 2
fi

PATCHCHECK=$(which patch)
if [ -z "$PATCHCHECK" ]; then
	echo I need patch to work, but you dont have it installed.
	exit 3
fi

# check if unstable was specified
while getopts "hu" OPTION; do
	case $OPTION in 
		h) echo Usage: viminstall.sh [-u]; exit 0
		;;
		u) echo "*** WARNING! Using unstable branch! ***"
         SOURCEURL=ftp://ftp.vim.org/pub/vim/unstable/unix/; 
         PATCHESURL=ftp://ftp.vim.org/pub/vim/unstable/patches/;
		;;
	esac		
done

# create the install directory if it does not exists
if [ ! -d $INSTALLPATH ]; then
	mkdir -p $INSTALLPATH
fi	

# create the build directory if it does not exists
if [ ! -d $BUILDPATH ]; then
	mkdir -p $BUILDPATH
fi	
echo Moving to $BUILDPATH 
cd $BUILDPATH

echo Installing a new Vim version on $INSTALLPATH
URL=$SOURCEURL
echo Checking for the latest version on $URL
LATEST_SOURCE=$(lynx --source $URL | grep -o "vim-[a-z0-9\.\-]\+\.bz2" | sort | uniq | tail -n1)
echo Latest Vim version is $LATEST_SOURCE

echo Downloading it ...
wget -c $URL/$LATEST_SOURCE -o /tmp/$$.vim

echo Extracting it ...
tar xvjf $LATEST_SOURCE 2>&1 > /dev/null

# find the vim dir after extracted
VIMDIR=$(find -type d -iname 'vim*' | sort | tail -n1)
echo Vim dir is $VIMDIR
cd $VIMDIR

# find the vim version
VIMVER=$(echo $VIMDIR | grep -o "[0-9]\+[a-z]\?")
VIMVERMAJOR=$(echo $VIMVER | cut -c1)
VIMVERMINOR=$(echo $VIMVER | cut -c2-)
VIMPATCHES=$PATCHESURL$VIMVERMAJOR.$VIMVERMINOR
echo Checking patches for version $VIMVERMAJOR.$VIMVERMINOR on $VIMPATCHES ...

# check if there are patches to download
PATCHES=$(lynx --source $VIMPATCHES | grep -o "$VIMVERMAJOR\.$VIMVERMINOR[0-9\.]\+" | sort | uniq)

if [ -z "$PATCHES" ]; then
	echo No patches found.
else
	# create the patches directory
	if [ ! -e patches ]; then
		mkdir patches
	fi		
	cd patches
	# download them all!
	for PATCH in $PATCHES; do
		if [ ! -e $PATCH ]; then
			echo Downloading patch $PATCH
			wget -c $VIMPATCHES/$PATCH -o /tmp/$$.vim
		else
			echo Skipping patch $PATCH
		fi			
	done
	# move back to apply them
	cd ..
	for PATCH in $PATCHES; do
		if [ -e patches/$PATCH ]; then
			echo Applying patch $PATCH
			patch -t -p0 < patches/$PATCH 2>&1 > /dev/null
		else
			echo Patch $PATCH does not exist?
		fi
	done
fi	

# configure it!
./configure \
--enable-gui \
--enable-gnome-check \
--enable-perlinterp \
--enable-pythoninterp \
--enable-rubyinterp \
--enable-cscope \
--enable-multibyte \
--enable-fontset \
--with-features=huge \
--with-compiledby=$COMPILEDBY \
--prefix=$INSTALLPATH

# if there were some erros, get out
if [ "$?" -ne "0" ]; then
	echo Seems there were some problems configuring. 
	echo After fix please run 
	echo make
	echo and
	echo make install
	echo to complete the installation.
	exit 4
fi

# and here we go
make
make install
exit 0
