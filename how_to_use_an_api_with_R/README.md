# Using the OpenAI API with {httr} to create pictures from a prompt

I wanted to see if there was a way to use the Open API (especially the DALL-E that was just opened in public beta).

The documentation only included examples in Python, Node.js and cURL. That's why I wanted to create this code example with R.

I acknowledge that there are two other use cases (edits and variations), but I wanted to start with the image creation one.

And when it comes to the code itself, I would like to replace the for loop in __6. Download the image(s)__ with some function from {purrr}.


## DISCLAIMER!
You need to open an account with https://openai.com/. And while there is a possibility for free credit when you start (at the time of writing $18 for three months), please notice that the requests are not free.

See the prices here: https://openai.com/api/pricing/. You can, of course, set a soft and a hard limit for usage per month.

One last thing, you can do other things with the API. See the full documentation here: https://beta.openai.com/docs/introduction/.