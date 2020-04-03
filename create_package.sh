#!/bin/sh

mkdir -p package

# $# represents the number of arguments.
if [ $# -gt 0 ]
then
  # Concatenate arguments with spaces.
  # (ref.) https://unix.stackexchange.com/questions/197792/joining-bash-arguments-into-single-string-with-spaces
  ARGS="'$*'"
  echo "Specified args: $ARGS"  
else
  echo "'cran linux' is set to ARGS"
  ARGS="cran linux"
fi


# Check whether string contains specific substring. 
# (ref.) https://www.shellscript.sh/case.html
# If you use bash, there are more ways. But using basic sh, this seems to be the best solution.
case "$ARGS" in
  *cran*)  
      echo "Building CRAN package"
      mkdir -p package/cran
      cp -R datasailr_pkg package/cran/
      cd package/cran
      R CMD build datasailr_pkg
      rm -R -f datasailr_pkg
      cd ../..
      echo "R CMD build finished successfully under cran directory"
      ;;
esac

case "$ARGS" in
  *linux*)  
      echo "Building binary package for Linux"
      mkdir -p package/binary_linux
      cp -R datasailr_pkg package/binary_linux/
      cd package/binary_linux
      R CMD INSTALL datasailr_pkg --build --no-multiarch
      rm -R -f datasailr_pkg
      cd ../..
      echo "R CMD build finished successfully under binary_linux directory"
      ;;
esac




