# Authentication

Sessions stored in database (new) and encrypted (new).





# Testing Issues

When enabling 2fa for the first time via the profile page:

1. I put in the wrong code a couple times to make sure it works before putting in the correct code. This cases an error (Action not allows) when I eventually put in the right one.
2. The Disable / Reset / Get 2FA QRcode buttons do not work as the JavaScript to determine the action cannot find the buttons. Don't think I broke it but I may have. The way you're doing it feels clunky - what about a per button listener to submit the form? Anyway, I just changed the form submit location manually to test.
