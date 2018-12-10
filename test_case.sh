#!/bin/bash
case $1 in
	1)
	echo "1.install"
	;;
	2)
	echo "2.uninstall"
	;;
	*)
	echo "Usage: $0 {1|2}"
esac
