#!/bin/bash

home=`pwd`
path=$home/EasyLife

fromDir=$path/en.lproj
toDir=$path/Base.lproj

cp "$fromDir"/*.strings "$toDir/"