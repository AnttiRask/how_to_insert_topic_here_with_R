# Load libraries ----
library(arrow)
library(duckdb)
library(shiny)
library(tidyverse)

# Create DuckDB connection ----
con <- dbConnect(duckdb())

# Read Parquet files directly using DuckDB ----
products_tbl <- dbGetQuery(
  con,
  "SELECT * FROM read_parquet('www/products.parquet')"
)

sales_tbl <- dbGetQuery(
  con,
  "SELECT * FROM read_parquet('www/sales.parquet')"
)

# Register DataFrames as tables
duckdb_register(con, "products_table", products_tbl)
duckdb_register(con, "sales_table", sales_tbl)

# Create Shiny dashboard ----

## UI ----
ui <- fluidPage(
  tags$head(
    # Bootstrap 3.4.1 CSS
    tags$link(
      rel = "stylesheet",
      href = "https://stackpath.bootstrapcdn.com/bootstrap/3.4.1/css/bootstrap.min.css"
    ),
    tags$script(src = "https://code.jquery.com/jquery-3.6.0.min.js"),
    tags$script(
      src = "https://stackpath.bootstrapcdn.com/bootstrap/3.4.1/js/bootstrap.min.js"
    )
  ),

  titlePanel("Sales Dashboard (R + Shiny + DuckDB)"),

  tabsetPanel(
    tabPanel("Revenue Per Product", plotOutput("revenuePlot")),
    tabPanel("Best-Selling Product", tableOutput("bestsellerTable")),
    tabPanel("Daily Sales Revenue", plotOutput("dailyPlot"))
  )
)

## Server ----
server <- function(input, output, session) {
  ### Query 1: Total Revenue per Product ----
  revenue_data <- reactive({
    dbGetQuery(
      con,
      "
      SELECT 
        p.product_name, 
        SUM(s.quantity * s.price) AS total_revenue
      FROM sales_table s
      JOIN products_table p ON s.product_id = p.product_id
      GROUP BY p.product_name
      ORDER BY total_revenue DESC
    "
    )
  })

  ### Query 2: Best-Selling Product ----
  bestseller_data <- reactive({
    dbGetQuery(
      con,
      "
      SELECT
        p.product_name, 
        SUM(s.quantity) AS total_quantity_sold
      FROM sales_table s
      JOIN products_table p ON s.product_id = p.product_id
      GROUP BY p.product_name
      ORDER BY total_quantity_sold DESC
      LIMIT 1
    "
    )
  })

  ### Query 3: Daily Sales Revenue ----
  daily_revenue_data <- reactive({
    dbGetQuery(
      con,
      "
      SELECT 
        sale_date, 
        SUM(quantity * price) AS daily_revenue
      FROM sales_table
      GROUP BY sale_date
      ORDER BY sale_date
    "
    ) %>%
      mutate(sale_date = as_date(sale_date))
  })

  ### Output 1: Total Revenue per Product ----
  output$revenuePlot <- renderPlot({
    ggplot(
      revenue_data(),
      aes(x = reorder(product_name, total_revenue), y = total_revenue)
    ) +
      geom_col(fill = "steelblue") +
      coord_flip() +
      scale_y_continuous(
        breaks = seq(0, 150, 50),
        expand = c(0, 0.5)
      ) +
      labs(x = NULL, y = NULL, title = NULL) +
      theme_bw()
  })

  ### Output 2: Best-Selling Product ----
  output$bestsellerTable <- renderTable({
    bestseller_data() %>%
      rename(
        "Product Name" = product_name,
        "Total Quantity Sold" = total_quantity_sold
      )
  })

  ### Output 3: Daily Sales Revenue ----
  output$dailyPlot <- renderPlot({
    ggplot(daily_revenue_data(), aes(x = sale_date, y = daily_revenue)) +
      geom_line(color = "steelblue", size = 2) +
      scale_x_date(
        date_labels = "%Y-%m-%d",
        expand = c(0, 0.1)
      ) +
      labs(x = NULL, y = NULL, title = NULL) +
      theme_bw()
  })
}

# Run the app
shinyApp(ui, server)
