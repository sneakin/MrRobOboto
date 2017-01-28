#!/bin/sh

ffmpeg -r 1 -f image2 -s `identify 01.png| cut -d " " -f 3` -i "%2d".png -vcodec gif -crf 1 -r 1 -s `identify 01.png| cut -d " " -f 3` output.gif
