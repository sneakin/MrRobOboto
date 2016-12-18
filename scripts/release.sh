#!/bin/sh

ROOT=`dirname $0`/..

cd "${ROOT}"
git ls-files > "${ROOT}"/MANIFEST
