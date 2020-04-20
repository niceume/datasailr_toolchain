#!/bin/sh

# $# represents the number of arguments.
if [ $# -gt 0 ]
then
  # Concatenate arguments with spaces.
  # (ref.) https://unix.stackexchange.com/questions/197792/joining-bash-arguments-into-single-string-with-spaces
  ARGS="'$*'"
  echo "Specified args: $ARGS"  
fi

# create folder called datasailr_pkg & base

mkdir -p datasailr_pkg
mkdir -p base

#############################################
# if files do not exist under each project directory
#   git clone
# else
#   git fetch
#############################################
case "$ARGS" in
  *no-git*)
echo "git is not used"
;;

  * ) 

cd base

if [ -d datasailr/.git ]
then 
  echo "git-pull : datasailr"
  cd ./datasailr
  git pull origin master
  cd ..
else
  git clone https://github.com/niceume/datasailr.git
fi

if [ -d libsailr/.git ]
then
  echo "git-pull : libsailr"
  cd ./libsailr
  git pull origin master
  cd ..
else
  git clone https://github.com/niceume/libsailr.git
fi

if [ -d Onigmo/.git ]
then
  echo "git-pull : Onigmo"
  cd ./Onigmo
  git pull origin master
  cd ..
else
  git clone https://github.com/k-takata/Onigmo.git
fi

cd ..

;;
esac

#############################################
# Merge them into datasailr_pkg

echo "update: datasailr_pkg/"
rsync -avr --delete --exclude '.gitignore' --exclude '.git' base/datasailr/ datasailr_pkg/

echo "update: datasailr_pkg/src/libsailr"
mkdir -p datasailr_pkg/src/libsailr
rsync -avr --delete --exclude '.gitignore' --exclude '.git' base/libsailr/ datasailr_pkg/src/libsailr

echo "update: datasailr_pkg/src/Onigmo"
mkdir -p datasailr_pkg/src/Onigmo
rsync -avr --delete --exclude '.gitignore' --exclude '.git' base/Onigmo/ datasailr_pkg/src/Onigmo

#############################################

echo "run autogen.sh for Onigmo"
cd datasailr_pkg/src/Onigmo
./autogen.sh
cd ../../..

echo "run autoconf and create configure script for DataSailr"
cd datasailr_pkg
autoconf
cd ..

echo "lt~obsolete.m4 is renamed to lt_obsolete.m4"
cd datasailr_pkg/src/Onigmo/m4
mv lt~obsolete.m4 lt_obsolete.m4 
cd ../../../..

echo "In src/Makevars.win, REQUIRE_AUTOTOOLS variable is switched to NO"
sed -i 's/.*REQUIRE_AUTOTOOLS=YES*/REQUIRE_AUTOTOOLS=NO/' datasailr_pkg/src/Makevars.win

echo "convert yacc file into c"
make y.tab.c --directory datasailr_pkg/src/libsailr/

echo "convert lex file into c"
make lex.yy.c --directory datasailr_pkg/src/libsailr/ 

echo "rename autogen.sh to autogen.sh.done"
mv datasailr_pkg/src/Onigmo/autogen.sh datasailr_pkg/src/Onigmo/autogen.sh.done

echo "delete src/Onigmo/doc b/c some systems misrecognize RE.ja as executable"
rm -R -f datasailr_pkg/src/Onigmo/doc/

echo "delete hidden files in Onigmo"
rm -R -f datasailr_pkg/src/Onigmo/.editorconfig
rm -R -f datasailr_pkg/src/Onigmo/.travis.yml
rm -R -f datasailr_pkg/src/Onigmo/m4/.gitkeep


###### printf related fixes ######

echo "Add #include <R_ext/Print.h> to all the related .c and .h files. Files: "
find datasailr_pkg/src/libsailr | egrep '(\.c|\.h)$' | xargs egrep -l '[[:space:]]*printf'

find datasailr_pkg/src/libsailr | egrep '(\.c|\.h)$' | xargs egrep -l '[[:space:]]*printf' | xargs sed -i '1i\
#include <R_ext/Print.h>
'

echo "Replace printf() with Rprintf()."

find datasailr_pkg/src/libsailr | egrep '(\.c|\.h)$' | xargs  sed -r -e '/^\s*printf/{
  s/^(\s*)printf(.*)$/\1Rprintf\2/g
}' -i


echo 'comment out all the printf() lines under libsailr'
grep -rl printf datasailr_pkg/src/libsailr  | xargs  sed -r -e '/^\s*printf/{
  :start
  /^(\s*printf.*;\s*\\)/d
  t success #goto :success label only when the last substutution succeeds
  s/^(\s*printf.*;)/\{\}\/\/\1/g
  t success #goto :success label only when the last substutution succeeds
  :loop
  N   #append the next line if substitution fails
  s/^(\s*printf.*;)/\/\*\1\*\//g
  t success
  T loop
  :success
}' -i


##############################

echo "Prevent R CMD build running cleanup scripts."
rm datasailr_pkg/cleanup.win
rm datasailr_pkg/cleanup


echo "Run compileAttr.sh"
cd datasailr_pkg
sh ./exec/compileAttr.sh
cd ..


echo "Disable compileAttr.sh (Package user does not need this command)"
sed -r -e '{
  s/^\s*#/&/
  t success
  s/^(.*)/#&/
  :success
}' -i datasailr_pkg/exec/compileAttr.sh


echo "Add third party library authors to DESCRIPTION "

cd datasailr_pkg
Rscript -e 'library(desc)' || exit 1

Rscript -e 'library(desc) 

mydesc = description$new("./DESCRIPTION")

# libsailr related authors
mydesc$add_author("Troy", "Hanson" , role=c("cph", "ctb"), comment="uthash")

mydesc$add_author("Howard", "Hinnant" , role=c("cph", "ctb"), comment="date.h")
mydesc$add_author("Adrian", "Colomitchi" , role=c("cph", "ctb"), comment="date.h")
mydesc$add_author("Florian", "Dang" , role=c("cph", "ctb"), comment="date.h")
mydesc$add_author("Paul", "Thompson" , role=c("cph", "ctb"), comment="date.h")
mydesc$add_author("Tomasz", "Kamiński" , role=c("cph", "ctb"), comment="date.h")

mydesc$add_author("Nemanja", "Trifunovic" , role=c("cph", "ctb"), comment="utfcpp")

mydesc$add_author("Kim", "Grasman" , role=c("cph", "ctb"), comment="getopt_port")


# onigmo related authors
mydesc$add_author("K.Kosako", role=c("cph", "ctb"), comment="onigmo author")
mydesc$add_author("K.Takata", role=c("cph", "ctb"), comment="onigmo author")
mydesc$add_author("Byte", "", role=c("cph", "ctb"), comment="onigmo contributor")
mydesc$add_author("KUBO", "Takehiro", role=c("cph", "ctb"), comment="onigmo contributor")
mydesc$add_author("Free Software Foundation, Inc", role=c("cph"))
mydesc$add_author("X Consortium", role=c("cph"))

mydesc$write(file = "./DESCRIPTION")
' || exit 1

cd ..


#############################################


