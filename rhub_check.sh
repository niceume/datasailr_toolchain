#!/bin/sh

target_package=`ls -t1 package/src_cran/ |  head -n 1`
echo "Target package is ${target_package}"

# $# represents the number of arguments.
if [ $# -gt 0 ]
then
  # Concatenate arguments with spaces.
  # (ref.) https://unix.stackexchange.com/questions/197792/joining-bash-arguments-into-single-string-with-spaces
  ARGS="'$*'"
  echo "Specified args: $ARGS"  
else
  echo "'cran' is set to ARGS"
  ARGS="cran"
fi

cd package/src_cran/

Rscript -e 'library(rhub)
' || exit 1


case "$ARGS" in
  *cran*)  
Rscript -e "
library(rhub)
rhub::check_for_cran(path='${target_package}', valgrind=TRUE)
"
  ;;
esac

case "$ARGS" in
  *macos*)  
Rscript -e "
library(rhub)
rhub::check_on_macos(path='${target_package}')
"
  ;;
esac

case "$ARGS" in
  *solaris*)  
Rscript -e "
library(rhub)
rhub::check_on_solaris(path='${target_package}')
"
  ;;
esac

