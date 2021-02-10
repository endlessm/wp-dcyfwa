#!/bin/bash
mydir=$(readlink -f $(dirname $0))
cleanup_file=$mydir/content-cleanup.lst

while read glob || [[ -n $glob ]]; do
	rm -f -r -v $glob
done < $cleanup_file