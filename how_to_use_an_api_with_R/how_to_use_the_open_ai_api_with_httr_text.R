# Using the OpenAI API with {httr} to create text (R code, for example) from a prompt ----

# DISCLAIMER!
#
# You need to open an account at https://openai.com/.
#
# And while there is a possibility for free credit when you
# start (at the time of writing $5 for three months), please notice that the
# requests are not free.
#
# See the prices here: https://openai.com/api/pricing/.
#
# You can, of course, set a soft and a hard limit for usage per month.
#
# One last thing, you can do other things with the API. See the full
# documentation here: https://platform.openai.com/docs/introduction/overview

## 1. Loading necessary libraries and sourcing the secret ----
library(conflicted) # just to check if there are any conflicting functions
library(httr2)      # for making the API request
library(tidyverse)  # for everything else

# For obvious reasons I'm not storing my OpenAI API key on GitHub. All you
# need to do is create a similar secret.R file and store the key there. And
# don't forget to add a .gitignore file in the same directory and add secret.R
# in it to keep your API key safe as well.
source("../how_to_insert_topic_here_with_R/how_to_use_an_api_with_R/secret.R")


## 2. Create the API POST request ----

### Insert the arguments ----

# The text prompt. Explore!
prompt      <- "A step-by-step outline for a comic book about Love and Rockets type of stories."

# The number of texts
n           <- 1

# Max number of tokens used
max_tokens  <- 4000

# Temperature (between 0 and 1 where 1 is most risky)
temperature <- 0.5

# Model used
model       <- "text-davinci-003"

### Create the request ----

# The URL for this particular use case (see documentation for others)
url <- "https://api.openai.com/v1/completions"

# Gather the arguments as the body of the request
body    <- list(
    model       = model,
    prompt      = prompt,
    n           = n,
    temperature = temperature,
    max_tokens  = max_tokens
)

body

# For the request You need to replace the OPENAI_API_KEY with your own API key
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

### URL(s) - these will expire after an hour! ----
text <- request %>%
    resp_body_json() %>%
    pluck("choices") %>%
    unlist() %>%
    pluck("text")

text %>%
    cat()

## 6. Save the text output in a txt file ----
file_text <- str_glue("how_to_use_an_api_with_R/output/open_ai_text_creation_{created}_text.txt")

text %>% 
    cat(file = file_text)
    

## 7. Save the metadata in a txt file ----

# In case you want to know how a particular text output was created, we'll gather all the info.
metadata <- tibble(
    created,
    model,
    prompt,
    n,
    max_tokens,
    temperature
)

file_meta <- str_glue("how_to_use_an_api_with_R/output/open_ai_text_creation_{created}_meta.txt")

# Write the file. Chose a txt file for the ease of use, but with the delimiters,
# it's still easy enough to read in in a tabular format.
metadata %>%
    write_delim(
        file  = file_meta,
        delim = ";"
    )
