#!/bin/bash

rm -f sms-hook-fortune.zip
zip -rq sms-hook-fortune.zip index.js node_modules

ibmcloud fn action update sms-fortune/incoming-webhook-js --kind nodejs:8 --web true sms-hook-fortune.zip

