#!/bin/sh

# ls -t : sort files based on timestamp
# ls -1 : print each file row by row
# head -n 1 : select 1st row
# basename : extract filename from path
target_package=`ls -t -1 build/src_pkg/datasailr_* | head -n 1 | xargs basename`

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

cd build/src_pkg/

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
  *linux*)  
echo "linux platforms"
Rscript -e "
library(rhub)
platforms = c(
'debian-clang-devel',
'debian-gcc-devel',
'fedora-clang-devel',
'fedora-gcc-devel',
'ubuntu-gcc-devel',
'linux-x86_64-centos6-epel',
'linux-x86_64-centos6-epel-rdt'
)
for(platf in platforms){
  rhub::check(path='${target_package}', platform= platf)
}
"
  ;;
esac

case "$ARGS" in
  *windows*)  
echo "windows platforms"
Rscript -e "
library(rhub)
platforms = c(
'windows-x86_64-devel',
'windows-x86_64-release')
for(platf in platforms){
  rhub::check(path='${target_package}', platform=platf)
}
"
  ;;
esac

case "$ARGS" in
  *macos*)  
echo "macos platforms"
Rscript -e "
library(rhub)
rhub::check_on_macos(path='${target_package}')
"
  ;;
esac

case "$ARGS" in
  *solaris*)  
echo "solaris platforms"
Rscript -e "
library(rhub)
rhub::check_on_solaris(path='${target_package}')
"
  ;;
esac

case "$ARGS" in
  *san*)  
echo "sanitizer available platform"
Rscript -e "
library(rhub)
rhub::check_with_sanitizers(path='${target_package}')
"
  ;;
esac




