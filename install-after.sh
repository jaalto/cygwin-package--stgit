#!/bin/sh
#
# install-after.sh -- Custom installation
#
# The script will receive one argument: relative path to
# installation root directory. Script is called like:
#
#    $ install-after.sh .inst
#
# This script is run after [install] command.

set -e

Environment()
{
    DOCDIR=$(cd $root/usr/share/doc/stgit-*/; pwd)
}

Cmd()
{
    echo "$@"
    [ "$test" ] && return
    "$@"
}

FixDocs()
{
    # For some reason hese are symlinks. Replace with real files

    for file in $DOCDIR/*
    do
      [ -h $file ] || continue

      rm $file
      cp $root/../Documentation/$(basename $file) $DOCDIR/
    done

    dir=$root/usr/share/doc/stgit

    [ -d $dir ] && Cmd rmdir $dir
}

MoveDirs()
{
    from=$root/usr/share/stgit

    for dir in $from/{contrib,examples}
    do
      [ -d $dir ] || continue
      Cmd mv $dir $DOCDIR/
    done
}

EchoIgnore ()
{
    echo ".... IGNORE MESSAGES: [sh: ../stg: No such file or directory]"
}

MakeManuals()
{
    echo ">> Wait, generating and installing manual pages"
    EchoIgnore

    man1=$root/usr/share/man/man1
    Cmd install -m 755 -d $man1

    for file in Documentation/stg*.txt
    do
        mansrc=$file
        man=$(echo $file | sed 's/.txt/.1/')

        Cmd asciidoc \
            -o $man \
            --unsafe \
            -b xhtml11 \
            -d book \
            -a "encoding=iso-8859-15" \
            -a toclevels=3 \
            -a date="$(date '+%Y-%m-%d')" \
            $mansrc || exit 1

        Cmd install -m 644 $man $man1
    done

    EchoIgnore
}

Main()
{
    root=${1:-".inst"}

    if [ "$root"  ] && [ -d $root ]; then
        root=$(echo $root | sed 's,/$,,')  # Delete trailing slash
        Environment
        FixDocs
        MoveDirs
        MakeManuals
    fi
}

Main "$@"

# End of file
