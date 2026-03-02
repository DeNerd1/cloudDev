#!/bin/bash
echo "<h1> Hello wold </h1>" > index.html
nohup busybox httpd -f -p 9191