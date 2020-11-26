# DataSailr packaging toolchain

## Purpose

1. This datasailr_toolchain repository provides toolchain for building a developing version of [datasailr CRAN package](https://cran.r-project.org/web/packages/datasailr/index.html) by yourself.
    + This packaging toolchain combines [DataSailr]( https://github.com/niceume/datasailr ) with [libsair]( https://github.com/niceume/libsailr ) and [Onigmo]( https://github.com/k-takata/Onigmo ), and build R package.
2. If you need to modify or develop DataSailr package, it is recommended to work in this repository's framework
    + Modifying DataSailr package usually means modifying DataSailr part (mapping R data to C and converting the result of libsailr calculation to R data ) and/or modifying libsailr part (Sailr script parsing and its execution for values of each row that come from R)
    + These two codes are placed under base/ directory (once after executing "./create_datasailr_pkg.sh"), and they are simply managed under git.
        + You can freely track changes using git.
        + You can also manage them on your remote repositoriy. (In this case, please change the default remote repositories hard coded in ./create_datasailr_pkg.sh )
    + (Note) Source codes are to be combined under tmp/datasailr_pkg, but I do not recommend code modification there. Even if you modify codes there, the changes are easily discarded when you re-run ./create_datasailr_pkg.sh. Please modify source codes under base/ direcotry.
        + If you do not like what you have changed, reset using git or delete directories under base/ and re-run ./create_datasailr_pkg.sh.


## How to use

There are two main shell scripts, './craete_datasailr_pkg.sh' and './create_package.sh', for building the package.

* './create_datasailr_pkg.sh' 
    1. 'git clone' libsailr, Onigmo and datasailr ('git pull' if respository already exists) under base/ directory. (If base/ does not exist yet, it is created.)
        + If no-git is passed, this step is skipped. (e.g.) './create_datasailr_pkg.sh no-git' 
    2. Clean up tmp/ directory if exists
        + If no-preclean is passed, this step is skipped. (e.g.) './create_datasailr_pkg.sh no-preclean'
    3. Sync datasailr source tree from base/datasailr to under tmp/ diretory using rsync, followed by syncing libsailr and Onigmo under tmp/datasailr_pkg/src/ using rsync.
    4. Conduct souce modifications for CRAN package (details are mentioned later)
* './create_package.sh'
    1. Copy tmp/datasailr_pkg under build/src_pkg and build/binary_pkg directories.
    2. Under build/src_pkg, 'R CMD build datasailr_pkg 'is executed, which creates source package.
    3. Under build/binary_pkg, 'R CMD INSTALL datasailr_pkg --build' is executed, which creates binary pacakge.
        + Note that this step also installs the current datasailr package to your system if it is successfully built.
        + Note that switching on/off debug option is now supported by DataSailr's package installation.
            + Specifying the following option results in passing corresponding argument to R CMD INSTALL.
                + libsailr-debug passes  --configure-args="--enable-libsailr-debug"
                + datasailr-debug passes --configure-args="--enable-datasailr-debug"
                + (e.g.) ./create_package.sh libsailr-debug datasailr-debug


Some more scripts

* './rhub_check.sh'
    + Check the latest package under build/src_pkg on rhub builder. (You need to have 'rhub' package)
        + cran (default): Check on essential platforms and conduct valgrind check.
        + linux, windows, macos and so on.
* './valgrind_check.sh'
    + Run valgrind check locally for your current datasailr package installed. (You need to have valgrind installed on your system.)
* './clean_tmp.sh'
    + Just delete tmp/ directory.


## Details of source modification

To publish an R package on CRAN, you need to follow strict CRAN rules. For this purpose, some additional modifications are needed.

* Non-C/C++ codes need to be converted to C/C++ codes
    + Toolchain at CRAN does not have bison or flex. parse.y and lex.l are converted.
    + autogen.sh and autoconf are executed.
* printf() is changed to Rprintf().
    + Calling printf() in R package is not allowed as a CRAN package.
    + '#include <R_ext/Print.h>' need to be added to the source file that use Rprintf() function.
* Authors@R is updated in DESCRIPTION.
    + To ship with other libraries, copyright holders of those libraries need to be added.
* Some more small changes.
    + Add AM_MAINTAINER_MODE([enable]) to Onigmo's configure.ac


## Examples

### Case 1 (Build latest package by yourself)

```
# git clone(pull) under base/ directory
# Put datasailr code and other library codes together under tmp/datasailr_pkg/ directory with some modification.
./create_datasailr_pkg.sh

# From tmp/datasailr_pkg, create packages under build directory (build/src_pkg and build/binary_pkg)
# Note that if building binary package succeeds, the current package is installed to your system.
./create_package.sh
```

Enjoy DataSailr!


### Case2 (Develop or modify DataSailr by yourself)

```
# git clone(pull) under base/ directory
# Put datasailr code and other library codes together under tmp/datasailr_pkg/ directory with some modification.
./create_datasailr_pkg.sh
```

* Here, Modify files under base/libsailr and/or base/datasailr. Changes are managed under git. 
    + You can send 'pull request' from each repository.

```
# Update tmp/datasailr_pkg without git pull under base/
./create_datasailr_pkg.sh no-git

# Try to build
./create_package.sh
```

If build succeeds,

1. Make sure that tests pass
    + In R, 'datasailr::test_sail()'
2. Make sure that Rhub does not raise warnings
    + './rhub_check cran'
    + Rhub builder provides more platforms.
3. Make sure that valgrind does not complain
    + './valgrind_check'


Thank you very much for contributing to DataSailr package!


