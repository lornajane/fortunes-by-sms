#!/bin/bash

rm -f sms-fortune.zip
zip -rq sms-fortune.zip index.js node_modules

bx wsk action update sms-fortune/incoming --kind nodejs:8 --web raw sms-fortune.zip

