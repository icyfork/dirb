# Directory Bookmarks for BASH (c) 2009-2010 Ira Chayut, Version 101216
#
# To use, save this file as ~/.bashDirB and add the following line to ~/.bashrc:
#
#        source ~/.bashDirB
#
# DirB and its implementation in this file are the product of and
# copyrighted by Ira Chayut.  You are granted a non-exclusive, royalty-free
# license to use, reporduce, modify and create derivative works from DirB; 
# providing that credit is given to DirB as a source material.
#
# The lastest version is available from: http://www.dirb.info/.  Ira can
# be reached at ira@dirb.info.  
#
# By default DirB will have the shell echo the current working directory out
# to the title bars of Xterm windows.  To disable this behavior, comment
# out the next line.
PS1="\[\033]0;\w\007\]\t \!> "

# Remember old saved bookmarks as DB_<bookmark>:
# Thanks for the suggestion to Jason Priebe (jpriebe@cbcnewmedia.com)
if [ -e ~/.bashDirB_envvars ]
then
    source ~/.bashDirB_envvars
fi

# If the repository of bookmarks does not exist, create it
if  [ ! -e ~/.DirB ]
then
    mkdir ~/.DirB
fi

function h () {        # Thanks to Manuel Soriano manu@manu.ms
       echo "s       Save a directory bookmark"
       echo "g       go to a bookmark or named directory"
       echo "p       push a bookmark/directory onto the dir stack"
       echo "r       remove saved bookmark"
       echo "d       display bookmarked directory path"
       echo "sl      print the list of directory bookmarks"
       echo ""
       echo "Examples:"
       echo "    s xyz                  current directory is saved as xyz"
       echo "    s xyz ../../dir0/dir1  save relative directory as xyz"
       echo "    s xyz dir notes here   save directory with comments"
       echo "    g xyz                  go to bookmark xyz or to path xyz"
       echo "    p xyz                  go to bookmark/directory xyz"
       echo "                           and remember into the directory stack"
       echo "    p                      swap to two bookmarks"
       echo "    p +n                   rotate nth entry from top to top"
       echo "    p -n                   rotate nth entry from bottm to top"
       echo "    r xyz                  remove named bookmark"
       echo "    d xyz                  display directory name of bookmark xyz"
       echo "    sl -l                  long list"
       echo "    sl -p                  path list"
       echo "    sl \"*x\"                list all of all bookmarks *x"
       echo "    sl -l \"*x\"             long list all of all bookmarks *x"
}

# "s" - Save bookmark
function s () { 
    if [ -n "$2" ]
    then
	# build the bookmark file with the contents "$CD directory_path"
	( echo '$CD ' \"$2\" > ~/.DirB/"$1" ;) > /dev/null 2>&1
    else
	# build the bookmark file with the contents "$CD directory_path"
	( echo -n '$CD ' > ~/.DirB/"$1" ; 
	  pwd | sed "s/ /\\\\ /g" >> ~/.DirB/"$1" ; ) > /dev/null 2>&1

    fi

    # if the bookmark could not be created, print an error message and
    # exit with a failing return code
    if [ $? != 0 ]
    then
	echo bash: DirB: ~/.DirB/"$1" could not be created >&2
	false
    fi

    echo export db_$1=\'$(d "$1")\' >> ~/.bashDirB_envvars
    . ~/.bashDirB_envvars

    NAME="$1"
    shift; shift
    if [ -n "$1" ]
    then
        ( echo "echo $*" >> ~/.DirB/"$NAME" ;) > /dev/null 2>&1
    fi
}

# "g" - Go to bookmark
function g () { 
    # if no arguments, then just go to the home directory
    if [ -z "$1" ]
    then
	cd
    else
	# if $1 is in ~/.DirB and does not begin with ".", then go to it
	if [ -f ~/.DirB/"$1" -a ${1:0:1} != "." ]
	then 
	    # update the bookmark's timestamp and then execute it
	    touch ~/.DirB/"$1" ; 
	    CD=cd source ~/.DirB/"$1" ; 
	# else just do a "cd" to the argument, usually a directory path of "-"
	else
	    cd "$1"
	fi
    fi
}

# "p" - Push a bookmark
function p () { 
# Note, the author's preference is to list the directory stack in a single 
# column.  Thus, the standard behavior of "pushd" and "popd" have been 
# replaced by discarding the normal output of these commands and using a 
# "dirs -p" after each one.

    # if no argument given, then just pushd and print out the directory stack
    if [ -z "$1" ]
    then
	pushd > /dev/null && dirs -p

    # if $1 is a dash, then just do a "popd" and print out the directory stack
    elif [ "$1" == "-" ]
    then
	popd > /dev/null
	dirs -p
    else
	# if $1 is in ~/.DirB and does not begin with ".", then go to it
	# and then print out the directory stack
	if [ -f ~/.DirB/"$1" -a "${1:0:1}" != "." ]
	    then
		touch ~/.DirB/$1 ; 
		CD=pushd source ~/.DirB/$1 > /dev/null && dirs -p ; 

	# else just do a "pushd" and print out the directory stack
	else
	    pushd "$1" > /dev/null && dirs -p
	fi
    fi
}

# "sl" - Saved bookmark Listing
function sl () { 
    # if the "-l" argument is given, then do a long listing, passing any 
    # remaining arguments to "ls", printing in reverse time order.  Pass the
    # output to "less" to page the output if longer than a screen in length.
    #
    # if the "-p" argument is given, list the directory bookmarks and the paths
    # that they point to.  (Thanks to Francis Hulin-Hubard fhh@admin-linux.fr)

    if [ "$1" == "-l" ]
    then
	shift
	( cd ~/.DirB ;
	ls -lt $* | 
	    sed -e 's/  */ /g' -e '/^total/d' \
		-e 's/^\(... \)\([0-9] \)/\1 \2/' | 
	    cut -d ' ' -s -f6- | sed -e '/ [0-9] /s// &/' | less -FX ; )

    elif [ "$1" == "-p" ]
    then
	shift
	( cd ~/.DirB ;
	for i in `ls $*` 
	do
	    echo "$i:	$(d $i)"
	done ) | less -FX

    else
	( cd ~/.DirB ; ls -xt $* ; )
    fi
}

# "r" - Remove a saved bookmark
function r () { 
    # if the bookmark file exists, remove it
    if [ -e ~/.DirB/"$1" ]
    then
	rm ~/.DirB/"$1"
	sed -i_bak ~/.bashDirB_envvars -e "/export db_$1=/d" > /dev/null 2>&1

    # if the bookmark file does not exist, complain and exit with a failing code
    else
	echo bash: DirB: ~/.DirB/"$1" does not exist >&2
	false
    fi
}

# "d" - Display (or Dereference) a saved bookmark
# to use: cd "$(d xxx)"
function d () {  
    # if the bookmark exists, then extract its directory path and print it
    if [ -e ~/.DirB/"$1" ]
    then
	head -1 ~/.DirB/"$1" | sed -e 's/\$CD //' -e 's/\\//g' 

    # if the bookmark does not exists, complain and exit with a failing code
    else
	echo bash: DirB: ~/.DirB/"$1" does not exist >&2
	false
    fi
}
