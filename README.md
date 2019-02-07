# SMS Fortune Sample Demo

A simple serverless app to receive a webhook from [Nexmo's SMS Service](https://developer.nexmo.com/messaging/sms/overview) and respond with a fortune from [Ubuntu's excellent collection](https://packages.ubuntu.com/cosmic/fortune-mod) of fairly silly fortune cookies.

## Setup

For the full blog post, look here: https://www.nexmo.com/blog/2018/08/14/serverless-sms-nexmo-ibm-dr/

### 1. Register for an incoming number

You'll need this to receive SMS messages - [set up incoming number](https://developer.nexmo.com/account/guides/numbers#rent-virtual-numbers) before you start.

### 2. Set up environment variables

Set the variables **NEXMO_API_KEY** and **NEXMO_API_SECRET** to the relevant values for your account. Also set **NEXMO_NUMBER** to the number you bought in step 1 (we'll use it as the from number).

### 3. Deploy the serverless function

Before deploying a function for the first time, create the package:

```
ibmcloud fn package update sms-fortune -p apikey $NEXMO_API_KEY -p apisecret $NEXMO_API_SECRET -p nexmonumber $NEXMO_NUMBER
```

Each language has a `deploy.sh` file in its folder, run this script (I mean, read the script so you know what's happening: it zips all the dependencies and deploys the result)

### 4. Set up the webhook for incoming SMS

First we need to ask the serverless function what URL it has:

```
ibmcloud fn action get --url sms-fortune/incoming-php
```

Now paste that into the [settings screen on your Nexmo dashboard](https://dashboard.nexmo.com/settings).

**OR**

Configure from the command line instead:

```
nexmo link:sms [number] [url]
```

### 5. Send yourself a text

Send an SMS (with any content) to the number you set up and laugh at the daft message you get back :)


