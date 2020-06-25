#!/bin/sh

mkdir -p build

src_pkg_dir=build/src_pkg
binary_pkg_dir=build/binary_pkg

# $# represents the number of arguments.
if [ $# -gt 0 ]
then
  # Concatenate arguments with spaces.
  # (ref.) https://unix.stackexchange.com/questions/197792/joining-bash-arguments-into-single-string-with-spaces
  ARGS="'$*'"
  echo "Specified args: $ARGS"  
else
  echo "'src binary' is set to ARGS"
  ARGS="src binary"
fi


# Check whether string contains specific substring. 
# (ref.) https://www.shellscript.sh/case.html
# If you use bash, there are more ways. But using basic sh, this seems to be the best solution.
case "$ARGS" in
  *src*)  
      echo "Building ource package"
      mkdir -p ${src_pkg_dir}
      cp -R tmp/datasailr_pkg ${src_pkg_dir}/
      cd ${src_pkg_dir}
      R CMD build datasailr_pkg
      case "$ARGS" in
        *keep-build*) ;;
        *)
          rm -R -f datasailr_pkg
        ;;
      esac
      cd -
      echo "R CMD build finished successfully under src_pkg directory"
      ;;
esac

case "$ARGS" in
  *binary*)  
      echo "Building binary package for the current platform"
      mkdir -p ${binary_pkg_dir}
      cp -R tmp/datasailr_pkg ${binary_pkg_dir}/
      cd ${binary_pkg_dir}
      R CMD INSTALL datasailr_pkg --build
      case "$ARGS" in
        *keep-build*) ;;
        *)
          rm -R -f datasailr_pkg
        ;;
      esac
      cd -
      echo "R CMD build finished successfully under binary_pkg directory"
      ;;
esac




