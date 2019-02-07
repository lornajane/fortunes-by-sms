#!/bin/bash

rm -f sms-fortune.zip
zip -rq sms-fortune.zip index.php 

ibmcloud fn action update sms-fortune/incoming-php --kind php:7.2 --web raw sms-fortune.zip

