#!/bin/bash

echo "hello wolrd" > index.html
nohup busybox httpd -f -p 9191 &

