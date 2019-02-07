#!/bin/bash

rm -f sms-fortune.zip
zip -rq sms-fortune.zip index.js node_modules

ibmcloud fn action update sms-fortune/incoming-js --kind nodejs:8 --web raw sms-fortune.zip

