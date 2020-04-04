#!/bin/sh

targe_package=`ls -t1 package/src_cran/ |  head -n 1`

cd package/src_cran/

Rscript -e 'library(rhub)

' || exit 1

Rscript -e "
library(rhub)
rhub::check_for_cran(path='${targe_package}')
"

