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
    conflict_prefer("seq_along", "purrr", "base")
library(httr2)       # for making the API request
library(tidyverse)  # for everything else

# For obvious reasons I'm not storing my OpenAI API key on GitHub. All you
# need to do is create a similar secret.R file and store the key there. And
# don't forget to add a .gitignore file in the same directory and add secret.R
# in it to keep your API key safe as well.
source("how_to_use_an_api_with_R/secret.R")


## 2. Create the API POST request ----

### Insert the arguments ----

# The text prompt. Explore! Examples: https://labs.openai.com/
# prompt  <- "A hand drawn sketch of a UFO"
prompt  <- "The art of statistics"

# The number of images (1-10)
# n       <- 10
n       <- 4

# Image size (256x256, 512x512, or 1024x1024 pixels)
size    <- "1024x1024"

### Create the request ----

# The URL for this particular use case (see documentation for others)
url <- "https://api.openai.com/v1/images/generations"

# Gather the arguments as the body of the request
body    <- list(
    prompt = prompt,
    n      = n,
    size   = size
)

# For the request You need to replace the OPENAI_API_KEY with your own API key
# that you get after signing up: https://beta.openai.com/account/api-keys
request <- request(url) %>%
    req_headers(Authorization = str_glue("Bearer {OPENAI_API_KEY}")) %>%
    req_body_json(body) %>%
    req_perform()


## 3. Check the request was successful (status code should be 200) ----
request$status_code


## 4. Let's take a look at the content ----
request %>%
    resp_body_json() %>% 
    glimpse()


## 5. Save the individual elements ----

# Select the timezone. See the list: OlsonNames().
tz <- "Europe/Helsinki"

### Created (time) ----
created <- request %>%
    resp_body_json() %>%
    pluck(1) %>%
    as_datetime(tz = tz) %>%
    ymd_hms() %>%
    as.character() %>%
    str_replace_all("\\s", "-") %>%
    str_replace_all("\\:", "-")

created

### URL(s) - these will expire after an hour! ----
url_img <- request %>%
    resp_body_json() %>%
    pluck(2) %>%
    unlist()

url_img

## 6. Download the image(s) and write the metadata in a txt file ----

# Metadata generation
metadata <- url_img %>%
    # Create a sequence from 1 to the length of 'url_img'
    seq_along() %>%
    # Use 'map2_df()' to apply a function to each element in the sequence and the corresponding URL in 'url_img'
    map2_df(
        # '.x' refers to the current element in the sequence
        .x = .,
        # '.y' refers to the current URL
        .y = url_img,
        # The function is specified using the '~' symbol
        # It generates a filename, downloads the file, and returns a tibble
        ~{
            # Create the destination file name
            destfile <- str_c(
                "how_to_use_an_api_with_R/images/dall-e-",
                created,
                "-",
                .x,
                ".png"
            )
            
            # Download the file at the current URL '.y' and save it to 'destfile'
            download.file(.y, destfile, mode = "wb")
            
            # Create a one-row tibble with the metadata for the current file
            tibble(
                prompt   = prompt,     
                n        = n,
                size     = size,       
                created  = created,
                url_img  = .y,
                destfile = destfile
            )
        })

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
