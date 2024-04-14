# Using the OpenAI API with {httr} to create pictures from a prompt

I wanted to see if there was a way to use the Open API.

The documentation only includes examples in Python, Node.js and cURL. That's why I wanted to create this code example with R.

I acknowledge that there are other use cases (edits and variations), but I wanted to start with the image creation one. I then went on to also make a version for text creation.

Now I know there nowadays are R packages that handle these two use cases and more. But it's important to learn things the hard way and this was that for me.


## DISCLAIMER!
You need to open an account with https://openai.com/. Please notice that the requests are not free.

See the prices here: https://openai.com/api/pricing/. You can, of course, set a soft and a hard limit for usage per month.

One last thing, you can do other things with the API. See the full documentation here: https://platform.openai.com/docs/overview/.