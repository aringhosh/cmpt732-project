#!/usr/bin/env bash
rm -r output**
python3 analysis.py --col=MASTERYR,MONTH,BIASMO1EXTNEW,COUNT\(OFFCOD1\) --con=MASTERYR,\>,2013 --grp=MASTERYR,MONTH,BIASMO1EXTNEW
