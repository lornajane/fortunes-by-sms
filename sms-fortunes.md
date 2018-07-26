# Reply to an SMS with a Fortune Cookie

Communicating with users via SMS is a great way of interacting with people in an informal way.  Whether you are automating response to your most-asked questions, running a competition, or connecting with your users over something completely different, SMS is a great choice.  In this post, we'll look at a fun and trivial example while we look at the detail of how to achieve these tasks. We'll build a system that responds to an incoming SMS with a "fortune cookie".  These are the greetings used in the "message of the day" feature on old *nix workstations, think of it as a geekier version of the adorable loading messages you see on Slack.

To implement this feature, a serverless function is used to receive the webhook.  Serverless is an ideal choice for a task like this where each incoming message is independent of all the others.  Serverless platforms like [IBM Cloud Functions](https://www.ibm.com/cloud/functions) (used in this example), [Amazon Lambda](https://aws.amazon.com/lambda/) or [Azure Functions](https://azure.microsoft.com/en-us/services/functions/) all scale horizontally when under load.  The big benefit is in the pricing model; you are only charged while your function is running so there is no need to pay a steady fee for a running server.  As an extra bonus, there are fewer steps involved to deploy a function than to set up a server, making it quicker to get started.

## Before you begin

There are some pre-requisites that you will need before you follow this tutorial:

* An [incoming number](https://dashboard.nexmo.com/your-numbers) to receive SMS on
* An [IBM Cloud account](https://www.ibm.com/cloud/) so we can deploy our serverless function (it's free)
* The `bx` command line tool for IBM Cloud and `wsk` Cloud Functions plugin - use the [setup instructions](https://console.bluemix.net/openwhisk/learn/cli).  Log in and set your [target workspace](https://console.bluemix.net/docs/cli/reference/bluemix_cli/bx_cli.html#bluemix_target) before you move on.

## Step 1: Create and deploy a serverless function

A serverless function is a function (this one is JavaScript; lots of programming languages are supported) deployed to the cloud.  The function will run in response to an event, and one of the common events is a web request.  By creating a single function and deploying it, we can quickly be ready to receive an SMS from a user.

Get the function from [this link to a specific version on GitHub](https://raw.githubusercontent.com/lornajane/fortunes-by-sms/cda960f486b08bc026b81f738f745281bd26dd79/index.js).  You should have content that looks something like this shortened version:

```js

function main(params) {
    // pick a random cookie from the data
    var data = getCookies();
    var random = Math.floor(Math.random() * 430);
    var cookie  = data[random];

    // log the cookie and then return it as body data
    console.log(cookie);
    return({"body": cookie});
}

function getCookies() {
    return [
        "A day for firm decisions!!!!! Or is it? ",
        // ~400 more lines
        "Your talents will be recognized and suitably rewarded. ",
        "Your temporary financial embarrassment will be relieved in a surprising manner. ",
        "Your true value depends entirely on what you are compared with. "
    ]
}
```

Save the content in `index.js` and take a little look at the `main()` function at the top.  It's a few lines of code to grab that big array of fortune cookies (from [Ubuntu's `fortune-mod` package](https://packages.ubuntu.com/cosmic/fortunes-ubuntu-server), no less) and pick one at random, before logging and returning it.  If you'd like to edit the `getCookies()` function to offer alternative fortune cookies, go ahead!

> In serverless programming, "functions" are usually referred to as "actions".

To get that action into the cloud, we'll first create a _package_ to put it in.  This helps to keep actions together and allows them to share parameters.

Using the `bx` command you set up earlier, create the package using this command:

```
bx wsk package create sms-fortune
```

You should see some "OK" happy output and with the package in place, we can go ahead and deploy the function as well.  Here's the command for that:

```
bx wsk action update sms-fortune/incoming --kind nodejs:8 --web raw index.js
```

Again, look to see the "OK" that indicates that the command completed succesfully.  We've deployed a function.  It's called `incoming` (since it will handle incoming SMS) and it exists within the `sms-fortune` package.  The other arguments here are `--kind` to say which version of JS to use and `--web raw` to immediately enable us to make a web request to this action.

> Calling `update` on an action that doesn't exist will make a `create` run instead, so this command works regardless of the current state.  Even better: it will still work if you want to edit `index.js` and deploy again.

So, what are we waiting for?  Let's find out the URL for our action and then request it.  Here's the command to discover what URL the action has:

```
bx wsk action get --url sms-fortune/incoming
```

Copy the URL from the response to the above command.  You can go ahead and use [cURL](https://curl.haxx.se/), your browser or any other HTTP client to make a request to that URL.  If everything has gone to plan, the response should include a witty remark.  Repeat the request a few times for further wittiness if desired.

## Step 2: Handle an incoming SMS

We're all set up with the endpoint that our webhook should point to, so let's go ahead and wire that up.  You can also checkout our [building block for receiving SMS](https://developer.nexmo.com/messaging/sms/building-blocks/receiving-an-sms) for reference.

First of all, we need a way to see when our function is called.  So far we have requested it directly, but when receiving an SMS there won't be a response that we can see.  Instead, open a new terminal window and start viewing the logs of your actions with the following command:

```
bx wsk activation poll
```

Leave this running (I like to put it on my second monitor if I have one) and use the same curl/browser request from before so you can see what happens when the function runs.  As you may notice, it's not real time and we sometimes need to wait a few seconds for the logs to appear.

Now we can tell when the function is running successfully, let's try making it our endpoint for SMS.  Visit your [Numbers](https://dashboard.nexmo.com/your-numbers) page on the Nexmo dashboard and click "Edit" on the number to use, and under "SMS" paste the action URL into the "Webhook URL" field.  Don't forget to click "Update".

We're all set: send an SMS to your incoming number, and watch those logs to see the action run!

## Step 3: Discover the number to respond to

At this point, we've deployed a serverless action and set it as the endpoint for the incoming SMS webhook to use.  To be able to reply to the user that sent the SMS, we need to inspect the data coming in with the webhook to see who sent it.

The IBM Cloud Functions (and indeed Apache OpenWhisk in general) actions accept a single parameter, which in this example is called `params`.  If you add `console.log(params)` to your code, you can see everything that we receive when the function runs.  Checking the [API docs for incoming SMS](https://developer.nexmo.com/api/sms#inbound-sms), we can see that the phone number we want to reply to will arrive as a query parameter called `msisdn`.

To capture the phone number, we can add a section to the `main()` function (just before returning) to grab the incoming variables into an array called `query_data` so we can use them:

```js
    // who are we texting? Get phone number
    var query_pieces = params.__ow_query.split('&');
    var query_data = [];
    query_pieces.forEach(function(item) {
        item_pieces = item.split('=');
        query_data[item_pieces[0]] = item_pieces[1];
    });
    console.log("Destination: " + query_data['msisdn']);
```

This isn't pretty, and you should be super careful about what happens in your code if these variables aren't present, but if you add this section to `index.js` and then redeploy using the same command as before:

```
bx wsk action update sms-fortune/incoming --kind nodejs:8 --web raw index.js
```

While still watching those logs, Send an SMS to your incoming number again.  This time, you should see the line `Destination:` and the phone number you sent the message from appearing in the logs.  We've got the information we need to be able to text back.

## Step 4: Set up some secrets

We can receive the incoming SMS by webhook because we had to set the URL that the data is sent to by logging into our account.  Before we can send the reply SMS though, we need to be able to authenticate.

For this section, you will need your API key and API secret handy - these are shown at the top of your [Nexmo dashboard](https://dashboard.nexmo.com/getting-started-guide).  To follow best practice for handling secrets like these, we'll avoid writing these values to files at all and instead we'll use [environment variables](https://en.wikipedia.org/wiki/Environment_variable).  The idea is that we set the variables for the current environment; if you open a new terminal window or reboot your computer, they will be forgotten and you'll have to set them again.

The variables to set are `NEXMO_API_KEY` and `NEXMO_API_SECRET`, and the commands look like this (replace your values after the `=` signs);

```
export NEXMO_API_KEY=awesomeKey
export NEXMO_API_SECRET=awesomeSecret
```

Now that our current environment knows the secrets, we can use them in our commands.

Next we're going to teach these secrets to the package we created earlier.  We do this by updating it and setting the parameters as we do so.  Here's the command:

```
bx wsk package update sms-fortune -p apikey $NEXMO_API_KEY -p apisecret $NEXMO_API_SECRET
```

These parameters aren't in our code but they're in the package so they are available to our action since it is in the same package.  If you add the `console.log(params)` command to your action now, then deploy it and watch the logs while you run it, you'll see these values.

This means we have all the information we need to send the reply SMS: the cookie, the phone number, and our API credentials.

## Step 5: Send fortune cookie by SMS

To return an SMS to the same number that sent a message to us in the first place, we'll need to make an API call; this section deal with this final piece of the puzzle.  You may also find our [building block for sending SMS](https://developer.nexmo.com/messaging/sms/building-blocks/send-an-sms) useful to refer to.

One thing to look out for with serverless JavaScript is that it doesn't have an [event loop](https://developer.mozilla.org/en-US/docs/Web/JavaScript/EventLoop) in quite the same way that we're used to.  As a result, all asynchronous operations such as database queries or the API request we're about to make in our code all need to be promisified or handled using async/await.  This example uses the [`request-promise`](https://www.npmjs.com/package/request-promise) library to enabled this promisified API call.

Adding libraries creates a little bit more complexity than we've had so far with everything in one `index.js` file, but it's nothing we can't handle.

To start with, we'll need a `package.json` file.  Mine looks like this:

```json
{
    "name": "sms-fortunes",
    "description": "Simple demo for getting a fortune cookie by SMS",
    "dependencies": {
        "request": "^2.85.0",
        "request-promise": "^4.2.2"
    }
}
```

You can also copy this file [from GitHub](https://github.com/lornajane/fortunes-by-sms/blob/master/package.json).  Edit if you wish (you probably don't need to) and then install these dependencies with `npm`:

```
npm install
```

When we deploy our action, we need to include the libraries as well as the `index.js` file.  To achieve this we can zip up everything we need into one file and deploy that instead.  Since this is a multi-step process (okay, two steps, but still) I like to create a script to handle it.  This way, I never forget to recreate the zip file, or forget to push it to the cloud, or whatever else there is to forget!

Here's my `deploy.sh` file (and again you can find the original [on GitHub](https://github.com/lornajane/fortunes-by-sms/blob/master/deploy.sh):

```
#!/bin/bash

rm -f sms-fortune.zip
zip -rq sms-fortune.zip index.js node_modules

bx wsk action update sms-fortune/incoming --kind nodejs:8 --web raw sms-fortune.zip
```

This script deletes the old zip file, adds our file and requirements to a new one, and then runs the same action update code that we were using earlier but supplying the zip file instead.  Let's update `index.js` to use our lovely new libraries and then use either this script or the commands shown above to deploy the action.

> To use `deploy.sh`, you will need to make it executable for your user so you can run it

Grab the updated version of `index.js` from [this resource on GitHub](https://raw.githubusercontent.com/lornajane/fortunes-by-sms/c26760eb1dd2347b653968069229ed8d68a0ef30/index.js) and put it in your project.  This version (but shortened) is shown below:

```js
const rp = require('request-promise');

exports.main = function (params) {
    // choose a fortune cookie for this user
    var data = getCookies();
    var random = Math.floor(Math.random() * 430);
    var cookie  = data[random];
    console.log("Fortune: " + cookie);

    // who are we texting? Get phone number
    // WARNING fails horribly if this data isn't present
    var query_pieces = params.__ow_query.split('&');
    var query_data = [];
    query_pieces.forEach(function(item) {
        item_pieces = item.split('=');
        query_data[item_pieces[0]] = item_pieces[1];
    });
    console.log("Destination: " + query_data['msisdn']);

    // text the cookie to the user who texted us
    var options = {
        method: 'POST',
        uri: "https://rest.nexmo.com/sms/json",
        body: {
            from: "SMS Fortunes Demo",
            text: cookie,
            to: query_data['msisdn'],
            api_key: params.apikey,
            api_secret: params.apisecret
        },
        json: true
    };

    return rp(options).then(function (response) {
        // response has info from Nexmo SMS service
        return Promise.resolved({"statusCode": 200, "body": cookie});
    });
}

function getCookies() {
    return [
        "A day for firm decisions!!!!! Or is it? ",
        // ~400 more lines
        "Your talents will be recognized and suitably rewarded. ",
        "Your temporary financial embarrassment will be relieved in a surprising manner. ",
        "Your true value depends entirely on what you are compared with. "
    ]
}
```

Put this all together, zip it up, deploy it, keep watching the logs just in case anything unexpected happens .... and send an SMS to your incoming number.  Tada!  A daft fortune cookie in response :)

## Conclusion

SMS is easy for users and hopefully from this example you've seen that for developers it is also pretty achievable.  The code here receives SMS and identifies the user, then sends an SMS back to the same user.  It uses a serverless backend because it's cheap to run and easy to get started with.  This example returned some trivial content but I'm sure it will give you ideas for your own applications.  For example you could parse the incoming message and give different responses based on it, or make a call to an API to get content rather that having it hardcoded as we did in this post to keep things simple.  The sky is the limit and we would love to know what you make!

## Next steps

If this has piqued your interest in doing more with SMS, here are some ideas for things to try next:

* A discussion of different messaging types and bots: https://www.nexmo.com/blog/2017/09/14/ai-bot-messaging-push-notifications-sms-dr/
* This excellent introduction to both SMS and Voice calling https://www.nexmo.com/blog/2017/03/03/sms-voice-programmable-communications-dr/
* An SMS group chat example application (in PHP) https://www.nexmo.com/blog/2017/03/03/sms-voice-programmable-communications-dr/
* A higher-level post about how SMS can help you to engage with your users: https://www.nexmo.com/blog/2016/07/22/top-5-ways-to-use-sms-to-increase-mobile-user-acquisition-and-engagement/




<!--stackedit_data:
eyJoaXN0b3J5IjpbLTQ3MTM1OTU2Nl19
-->