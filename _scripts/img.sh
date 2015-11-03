#!/bin/sh
convert $1 -scale 20% -quality 86 -strip assets/$2
