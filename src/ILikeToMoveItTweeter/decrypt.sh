#!/bin/sh
BASE=${1:-iliketomoveit.ini}
BASE=$(basename ${BASE} .enc)
openssl enc -d -aes256 -in ${BASE}.enc -out ${BASE}


