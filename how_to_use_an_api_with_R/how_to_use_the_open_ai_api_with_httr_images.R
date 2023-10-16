# Using the OpenAI API with {httr} to create pictures from a prompt ----

# DISCLAIMER!
#
# You need to open an account at https://openai.com/.
#
# And while there is a possibility for free credit when you
# start (at the time of writing $18 for three months), please notice that the
# requests are not free.
#
# See the prices here: https://openai.com/api/pricing/.
#
# You can, of course, set a soft and a hard limit for usage per month.
#
# One last thing, you can do other things with the API. See the full
# documentation here: https://beta.openai.com/docs/introduction/overview

## 1. Loading necessary libraries and sourcing the secret ----
library(conflicted) # just to check if there are any conflicting functions
library(httr)       # for making the API request
library(tidyverse)  # for everything else
library(lubridate)  # for manipulating the time stamp

# For obvious reasons I'm not storing my OpenAI API key on GitHub. All you
# need to do is create a similar secret.R file and store the key there. And
# don't forget to add a .gitignore file in the same directory and add secret.R
# in it to keep your API key safe as well.
source("how_to_use_an_api_with_R/secret.R")


## 2. Create the API POST request ----

### Insert the arguments ----

# The text prompt. Explore! Examples: https://labs.openai.com/
# prompt  <- "A hand drawn sketch of a UFO"
prompt  <- "Create an image illustrating the historical moment when the first domain name, Symbolics.com, was registered on March 15, 1985, by the computer manufacturer Symbolics. Depict a computer from the 1980s, the Symbolics logo, and the iconic domain name appearing on the screen, celebrating 'World Domain Day' and the birth of the internet's virtual real estate. Emphasize the revolutionary impact this event had on global communication, commerce, and society."

# The number of images (1-10)
# n       <- 10
n       <- 4

# Image size (256x256, 512x512, or 1024x1024 pixels)
size    <- "1024x1024"

### Create the request ----

# The URL for this particular use case (see documentation for others)
url_api <- "https://api.openai.com/v1/images/generations"

# Gather the arguments as the body of the request
body    <- list(
    prompt = prompt,
    n      = n,
    size   = size
)

# For the request You need to replace the OPENAI_API_KEY with your own API key
# that you get after signing up: https://beta.openai.com/account/api-keys
request <- POST(
    url_api,
    add_headers(Authorization = str_glue("Bearer {OPENAI_API_KEY}")),
    body = body,
    encode = "json"
)


## 3. Check the request was successful (status code should be 200) ----
request$status_code


## 4. Let's take a look at the content ----
request %>%
    content() %>%
    glimpse()


## 5. Save the individual elements ----

# Select the timezone. See the list: OlsonNames().
tz <- "Europe/Helsinki"

### Created (time) ----
created <- request %>%
    content() %>%
    pluck(1) %>%
    as_datetime(tz = tz) %>%
    ymd_hms() %>%
    as.character() %>%
    str_replace_all("\\s", "-") %>%
    str_replace_all("\\:", "-")
created

### URL(s) - these will expire after an hour! ----
url_img <- request %>%
    content() %>%
    pluck(2) %>%
    unlist() %>%
    as.vector()
url_img


## 6. Download the image(s) ----

### Use a for loop to go through each of the URLs in the url_img ----
for (i in seq_along(url_img)) {

    # Create the filename using dall-e, creation time stamp and a running number
    # at the end. For example: "dall-e-2022-11-05-22-16-12-1.png"
    destfile <- c(paste0("how_to_use_an_api_with_R/images/dall-e-", created, "-", i, ".png"))

    # Download the files mentioned in the url_img. Mode = "wb" is needed when
    # downloading binary files. Won't work without it.
    download.file(url_img[i], destfile, mode = "wb")

}


## 7. Write the metadata in a txt file ----

# In case you want to know how a particular image was created or wish to use the
# URL (for an hour, because it's gone after that), we'll gather all the info.
metadata <- tibble(
    prompt,
    n,
    size,
    created,
    url_img,
    destfile
)

# We'll use one file for all of the images created with the same prompt.
# By using a similar naming convention, you can easily find everything.
file <- str_glue("how_to_use_an_api_with_R/images/dall-e-{created}.txt")

# Write the file. Chose a txt file for the ease of use, but with the delimiters,
# it's still easy enough to read in in a tabular format.
metadata %>%
    write_delim(
        file  = file,
        delim = ";"
    )
