#!/bin/bash
#	Shell script to download and install Vim with the latest patches applied.
#
APPSDIR=build							# just a directory under your $HOME dir where apps will be installed
INSTALLDIR=$HOME/$APPSDIR/vim2	# this app, of course, is called vim
COMPILEDBY=TaQ							# put your name here to show it with :version

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

# create the directory if it does not exists
if [ ! -d $INSTALLDIR ]; then
	mkdir -p $INSTALLDIR
fi	
cd $INSTALLDIR

echo Installing a new Vim version on $INSTALLDIR
URL=ftp://ftp.vim.org/pub/vim/unix/
echo Checking for the latest version on $URL
LATEST_SOURCE=$(lynx --source $URL | grep -o "vim-[a-z0-9\.\-]\+\.bz2" | sort | uniq | tail -n1)
echo Latest Vim version is $LATEST_SOURCE

echo Downlading it ...
wget -c $URL/$LATEST_SOURCE -o /tmp/$$.vim

echo Extracting it ...
tar xvjf $LATEST_SOURCE 2>&1 > /dev/null

# find the vim dir after extracted
VIMDIR=$(find -type d -iname 'vim*')
echo Vim dir is $VIMDIR
cd $VIMDIR

# find the vim version
VIMVER=$(echo $VIMDIR | grep -o "[0-9]\+")
VIMVERMAJOR=$(echo $VIMVER | cut -c1)
VIMVERMINOR=$(echo $VIMVER | cut -c2)
echo Checking patches for version $VIMVERMAJOR.$VIMVERMINOR ...

# check if there are patches to download
VIMPATCHES=ftp://ftp.vim.org/pub/vim/patches/$VIMVERMAJOR.$VIMVERMINOR
PATCHES=$(lynx --source ftp://ftp.vim.org/pub/vim/patches/7.2/ | grep -o "7\.2[0-9\.]\+" | sort | uniq)

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
--prefix=$INSTALLDIR

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
