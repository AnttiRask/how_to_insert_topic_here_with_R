# Using the OpenAI API with {httr} to create pictures from a prompt ----

# DISCLAIMER!
#
# You need to open an account at https://openai.com/.
#
# Please notice that the requests are not free.
#
# See the prices here: https://openai.com/api/pricing/.
#
# You can, of course, set a soft and a hard limit for usage per month.
#
# One last thing, you can do other things with the API. See the full
# documentation here: https://platform.openai.com/docs/introduction/overview

## 1. Loading necessary libraries and sourcing the secret ----
library(conflicted) # just to check if there are any conflicting functions
    conflicts_prefer(purrr::seq_along)
library(httr2)      # for making the API request
library(tidyverse)  # for everything else

# For obvious reasons I'm not including my OpenAI API in the code. All you
# need to do is create a similar secret.R file and store the key there. And
# don't forget to add a .gitignore file in the same directory and add secret.R
# in it to keep your API key safe as well.
source("how_to_use_an_api_with_R/secret.R")


## 2. Create the API POST request ----

### Insert the arguments ----

# The model. Use Dall-E 3 for better quality, DALL-E 2 if you want more images.
model   <- "dall-e-3"
    
# The text prompt. Explore!
prompt  <- "Avenue of mysteries"

# The number of images. 1 if you're using Dall-E 3, up to 10 with Dall-E 2
n       <- 1

# Image size:
# 1024x1024, 1024x1792, or 1792x1024 when using Dall-E 3
# 256x256, 512x512, or 1024x1024 pixels when using Dall-E 2
size    <- "1024x1024"

### Create the request ----

# The URL for this particular use case (see documentation for others)
url <- "https://api.openai.com/v1/images/generations"

# Gather the arguments as the body of the request
body    <- list(
    model  = model,
    prompt = prompt,
    n      = n,
    size   = size
)

# For the request you need to replace the OPENAI_API_KEY with your own API key
# that you get after signing up: https://platform.openai.com/account/api-keys
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
    pluck("created") %>%
    as_datetime(tz = tz) %>%
    as.character() %>%
    str_replace_all("\\s", "-") %>%
    str_replace_all("\\:", "-")

created

### Revised prompt - we'll use this only for the metadata ----
revised_prompt <- request %>%
    resp_body_json() %>%
    pluck("data", 1, "revised_prompt")

revised_prompt

### URL(s) - these will expire after an hour! ----
url_img <- request %>%
    resp_body_json() %>%
    pluck("data", 1, "url")

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
                prompt         = prompt,
                revised_prompt = revised_prompt,
                n              = n,
                size           = size,       
                created        = created,
                url_img        = .y,
                destfile       = destfile
            )
        })

# We'll use one file for all of the images created with the same prompt.
# By using a similar naming convention, you can easily find everything.
file <- str_glue("how_to_use_an_api_with_R/images/dall-e-{created}.txt")

# Write the file. Chose a .txt file for the ease of use, but with the delimiters,
# it's still easy enough to read in in a tabular format.
metadata %>%
    write_delim(
        file  = file,
        delim = ";"
    )
