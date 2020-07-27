## Extra steps for the webhook version

Read the top-level README first!

Then, add a parameter "sharedsecret" to the package when you set the env vars. We'll need to send this with every request (because otherwise this code is open to the web and sends SMS to arbitrary numbers)

### To call the webhook

The URL can be obtained like this:

```
ibmcloud fn action get --url sms-fortune/incoming-webhook-js
```

Now you can do `[URL]?number=447770007788&sharedsecret=PinkBicycle` (replace with real values).
