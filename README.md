# SMS Fortune Sample Demo

A simple serverless app to receive a webhook from [Nexmo's SMS Service](https://developer.nexmo.com/messaging/sms/overview) and respond with a fortune from [Ubuntu's excellent collection](https://packages.ubuntu.com/cosmic/fortune-mod) of fairly silly fortune cookies.

## Setup

I'll link to the full tutorial when it's finished but here's the TL;DR version for using this project.

### 3. Register for an incoming number

You'll need this to receive SMS messages - [set up incoming number](https://developer.nexmo.com/account/guides/numbers#rent-virtual-numbers) before you start.

### 2. Set up environment variables

Set the variables **NEXMO_API_KEY** and **NEXMO_API_SECRET** to the relevant values for your system.

### 3. Deploy the serverless function

There's one I made earlier (look in `index.js`).  Deploy it like this:

```
bx wsk package update sms-fortune -p apikey $NEXMO_API_KEY -p apisecret $NEXMO_API_SECRET

zip -rq sms-fortune.zip index.js node_modules
bx wsk action update sms-fortune/incoming --kind nodejs:8 --web raw sms-fortune.zip
```

### 4. Set up the webhook for incoming SMS

First we need to ask the serverless function what URL it has:

```
bx wsk action get --url sms-fortune/incoming
```

Now paste that into the [settings screen on your Nexmo dashboard](https://dashboard.nexmo.com/settings).

### 5. Send yourself a text

Send an SMS (with any content) to the number you set up and laugh at the daft message you get back :)


