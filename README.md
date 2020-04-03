# DataSailr packaging toolchain

* This datasailr_pkg repository provides toolchain for building [datasailr CRAN package](https://cran.r-project.org/web/packages/datasailr/index.html).
* The main repository of DataSailr is at [datasailr]( https://github.com/niceume/datasailr ).


The DataSailr works with other libraries such as libsailr and onigmo. Those libraries can be linked dynamically, but for example, when publishing at CRAN, it is easier and more convenient for users to go without installing third party libraries by themselves. Also, to follow the strict CRAN rules, some additional modifications are needed.


* Add other libraries. 
    + Git those libraries and rsync them to under datasailr_pkg 
* Non-C/C++ codes need to be converted to C/C++ codes
    + Toolchain at CRAN does not have bison or flex. parse.y and lex.l are converted.
    + Run autogen.sh and autoconf if necessary.
* printf() is commented out.
* Authors and Authors@R are updated in DESCRIPTION.
    + To ship with other libraries, copyright holders of those libraries need to be added.
* Some more small changes.


```
# Create datasailr_pkg directory
# Put datasailr code and other library codes together.
# Conduct some modifications.
./create_datasailr_pkg.sh
```

```
# This program is assumed to be run on linux 
# ./ceate_package.sh creates packages for CRAN and linux.
./crate_package.sh

# If you want to create only CRAN package
./crate_package.sh cran

# If you want to create only linux package
./crate_package.sh linux
```


