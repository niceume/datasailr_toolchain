#!/bin/sh

datasailr_remote_repository="https://github.com/niceume/datasailr.git"
libsailr_remote_repository="https://github.com/niceume/libsailr.git"
onigmo_remote_repository="https://github.com/k-takata/Onigmo.git"

# $# represents the number of arguments.
if [ $# -gt 0 ]
then
  # Concatenate arguments with spaces.
  # (ref.) https://unix.stackexchange.com/questions/197792/joining-bash-arguments-into-single-string-with-spaces
  ARGS="'$*'"
  echo "Specified args: $ARGS"  
fi

case "$ARGS" in
  *no-preclean*) ;;
  *)
echo "Clean up tmp directory"
rm -R -f ./tmp
;;
esac

# create folder called datasailr_pkg & base

mkdir -p tmp
mkdir -p tmp/datasailr_pkg
mkdir -p base

#############################################
# if files do not exist under each project directory
#   git clone
# else
#   git pull
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
  git clone ${datasailr_remote_repository}
fi

if [ -d libsailr/.git ]
then
  echo "git-pull : libsailr"
  cd ./libsailr
  git pull origin master
  cd ..
else
  git clone ${libsailr_remote_repository}
fi

if [ -d Onigmo/.git ]
then
  echo "git merge : Onigmo(Feb 4 2021)"
else
  git clone ${onigmo_remote_repository}
fi
cd ./Onigmo
git checkout dd8a18af5c2f2871104b1bdbf3bbb597ec9e4665 -b temp  # Feb 4 2021
cd ..


cd ..

;;
esac

#############################################
# Merge them into tmp/datasailr_pkg

echo "update: tmp/datasailr_pkg/"
rsync -avr --delete --exclude '.gitignore' --exclude '.git' base/datasailr/ tmp/datasailr_pkg/

echo "update: tmp/datasailr_pkg/src/libsailr"
mkdir -p tmp/datasailr_pkg/src/libsailr
rsync -avr --delete --exclude '.gitignore' --exclude '.git' --exclude 'dev_env' base/libsailr/ tmp/datasailr_pkg/src/libsailr

echo "update: datasailr_pkg/src/Onigmo"
mkdir -p tmp/datasailr_pkg/src/Onigmo
rsync -avr --delete --exclude '.gitignore' --exclude '.git' base/Onigmo/ tmp/datasailr_pkg/src/Onigmo

#############################################

echo "apply patch for Onigmo"
cd tmp/datasailr_pkg/src/Onigmo
patch -p1 < ../../../../patch/Onigmo-dd8a18a.patch
cd ../../../..

echo "apply patch for date.h in libsailr"
cd tmp/datasailr_pkg/src/libsailr
patch -p1 < ../../../../patch/libsailr-date.h-0b33665.patch
cd ../../../..

echo "run autogen.sh for Onigmo"
cd tmp/datasailr_pkg/src/Onigmo
awk '/AC_CONFIG_HEADER/ && !done {print ; print "AM_MAINTAINER_MODE([enable])"; done=1 ; next }1' configure.ac > configure.ac.tmp && mv configure.ac.tmp configure.ac
./autogen.sh
cd ../../../..

echo "run autoconf and create configure script for DataSailr"
cd tmp/datasailr_pkg
autoconf --warnings=obsolete
cd ../..

echo "lt~obsolete.m4 is renamed to lt_obsolete.m4"
cd tmp/datasailr_pkg/src/Onigmo/m4
mv lt~obsolete.m4 lt_obsolete.m4 
cd ../../../../..

echo "In src/Makevars.win, REQUIRE_AUTOTOOLS variable is switched to NO"
sed -i 's/.*REQUIRE_AUTOTOOLS=YES*/REQUIRE_AUTOTOOLS=NO/' tmp/datasailr_pkg/src/Makevars.win

echo "convert yacc file into c"
make y.tab.c --directory tmp/datasailr_pkg/src/libsailr/

echo "convert lex file into c"
make lex.yy.c --directory tmp/datasailr_pkg/src/libsailr/ 

echo "rename autogen.sh to autogen.sh.done"
mv tmp/datasailr_pkg/src/Onigmo/autogen.sh tmp/datasailr_pkg/src/Onigmo/autogen.sh.done

echo "delete src/Onigmo/doc b/c some systems misrecognize RE.ja as executable"
rm -R -f tmp/datasailr_pkg/src/Onigmo/doc/

echo "delete hidden files in Onigmo"
rm -R -f tmp/datasailr_pkg/src/Onigmo/.editorconfig
rm -R -f tmp/datasailr_pkg/src/Onigmo/.travis.yml
rm -R -f tmp/datasailr_pkg/src/Onigmo/m4/.gitkeep


###### printf related fixes ######

echo "Add #include <R_ext/Print.h> to all the related .c and .h files. Files: "
find tmp/datasailr_pkg/src/libsailr | egrep '(\.c|\.h)$' | xargs egrep -l '[[:space:]]*printf'

find tmp/datasailr_pkg/src/libsailr | egrep '(\.c|\.h)$' | xargs egrep -l '[[:space:]]*printf' | xargs sed -i '1i\
#include <R_ext/Print.h>
'

echo "Replace printf() with Rprintf()."

find tmp/datasailr_pkg/src/libsailr | egrep '(\.c|\.h)$' | xargs  sed -r -e '/^\s*printf/{
  s/^(\s*)printf(.*)$/\1Rprintf\2/g
}' -i


echo 'comment out all the printf() lines under libsailr'
grep -rl printf tmp/datasailr_pkg/src/libsailr  | xargs  sed -r -e '/^\s*printf/{
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
rm tmp/datasailr_pkg/cleanup.win
rm tmp/datasailr_pkg/cleanup


echo "Run compileAttr.sh"
cd tmp/datasailr_pkg
sh ./exec/compileAttr.sh
cd ../..


echo "Disable compileAttr.sh (Package user does not need this command)"
sed -r -e '{
  s/^\s*#/&/
  t success
  s/^(.*)/#&/
  :success
}' -i tmp/datasailr_pkg/exec/compileAttr.sh


echo "Add third party library authors to DESCRIPTION "

cd tmp/datasailr_pkg

Rscript -e '
toolchain_file_to_lines = function( filename ){
    file_con = file(filename, "r")
    lines = readLines(con = file_con )
    close(file_con)
    return( lines )
}

toolchain_lines_to_file = function( lines, filename ){
    file_con = file(filename, "w")
    writeLines(lines, con = file_con , sep="\n")
    close(file_con)
}

toolchain_update_author_line = function(lines, new_authors_string){
    lines[toolchain_author_line_pos(lines)] = new_authors_string
    return(lines)
}

toolchain_extract_author_line = function( lines ){
    author_lines_logical = grepl("^Authors@R", lines )
    author_lines = lines[author_lines_logical]
    if(length(author_lines) == 1){
          return(author_lines)
    }else if(length(author_lines) <= 0){
        error("Authors@R lines does not exist. Check DESCRIPTION file again.")
    }else{
        error("Authors@R lines exist more than once. Check DESCRIPTION file again.")
    }
}

toolchain_author_line_pos = function( lines ){
    author_line_pos = grep("^Authors@R", lines )
    if(length(author_line_pos) == 1){
          return(author_line_pos)
    }else if(length(author_line_pos) <= 0){
        error("Authors@R lines does not exist. Check DESCRIPTION file again.")
    }else{
        error("Authors@R lines exist more than once. Check DESCRIPTION file again.")
    }
}

toolchain_parse_author_line = function( line ){
    authors_string = sub("^Authors@R:(.+)", "\\1", line)
    return( eval(parse(text=authors_string)))
}

toolchain_add_author = function( authors, given, ... ){
    current_author = person( given = given,  ... )
    authors = append(authors, current_author)
    return(authors)
}

toolchain_authors_string = function(authors){
    r_vec = format(authors, style = "R")
    r_vec = append( "Authors@R: " , r_vec)
    return( paste(r_vec, collapse="\n    " ))
}

lines = toolchain_file_to_lines("./DESCRIPTION")
line = toolchain_extract_author_line(lines)
authors = toolchain_parse_author_line(line)

### Additional authors from third party libraries
# libsailr_related authors
authors = toolchain_add_author(authors, "Troy", "Hanson", role=c("cph", "ctb"), comment="uthash")
authors = toolchain_add_author(authors, "Howard", "Hinnant", role=c("cph", "ctb"), comment="date.h")
authors = toolchain_add_author(authors, "Adrian", "Colomitchi", role=c("cph", "ctb"), comment="date.h")
authors = toolchain_add_author(authors, "Florian", "Dang", role=c("cph", "ctb"), comment="date.h")
authors = toolchain_add_author(authors, "Paul", "Thompson", role=c("cph", "ctb"), comment="date.h")
authors = toolchain_add_author(authors, "Tomasz", "Kamiński", role=c("cph", "ctb"), comment="date.h")
authors = toolchain_add_author(authors, "Jiangang", "Zhuang", role=c("cph", "ctb"), comment="date.h")

authors = toolchain_add_author(authors, "Nemanja", "Trifunovic" , role=c("cph", "ctb"), comment="utfcpp")

authors = toolchain_add_author(authors, "Kim", "Grasman" , role=c("cph", "ctb"), comment="getopt_port")

authors = toolchain_add_author(authors, "Jon", "Clayden" , role=c("cph", "ctb"), comment="ore package")

# onigmo related authors
authors = toolchain_add_author(authors, "K.Kosako", role=c("cph", "ctb"), comment="onigmo author")
authors = toolchain_add_author(authors, "K.Takata", role=c("cph", "ctb"), comment="onigmo author")
authors = toolchain_add_author(authors, "Byte", "", role=c("cph", "ctb"), comment="onigmo contributor")
authors = toolchain_add_author(authors, "KUBO", "Takehiro", role=c("cph", "ctb"), comment="onigmo contributor")

authors = toolchain_add_author(authors, "Free Software Foundation, Inc", role=c("cph"))
authors = toolchain_add_author(authors, "X Consortium", role=c("cph"))

### End of additional authors

new_authors_string = toolchain_authors_string(authors)
lines = toolchain_update_author_line(lines, new_authors_string)
toolchain_lines_to_file(lines, "./DESCRIPTION")
' || exit 1

cd ../..


#############################################


