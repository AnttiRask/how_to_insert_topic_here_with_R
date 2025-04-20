# Load libraries
library(arrow)
library(tidyverse)

# Create sales data
# fmt: skip
sales_data <- tibble(
  sale_id    = 1:5,
  product_id = c(101, 102, 101, 103, 104),
  quantity   = c(2, 1, 5, 3, 4),
  price      = c(20.5, 35.0, 20.5, 15.75, 40.0),
  sale_date  = ymd(c("2024-03-01", "2024-03-02", "2024-03-03", "2024-03-04", "2024-03-05"))
) %>%  mutate(across(c(sale_id, product_id, quantity), as.integer))

# Create products data
# fmt: skip
products_data <- tibble(
  product_id   = c(101, 102, 103, 104),
  product_name = c("Laptop", "Smartphone", "Headphones", "Monitor"),
  category     = c("Electronics", "Electronics", "Accessories", "Electronics"),
  price        = c(1000.0, 500.0, 150.0, 300.0)
) %>% mutate(product_id = product_id %>% as.integer)

# Write to Parquet files
write_parquet(sales_data, "duckdb-shiny/sales.parquet")
write_parquet(products_data, "duckdb-shiny/products.parquet")
