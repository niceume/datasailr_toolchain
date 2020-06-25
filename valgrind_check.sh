#!/bin/sh

R -d "valgrind --dsymutil=yes" -e "library(datasailr); datasailr::test_sail()"

