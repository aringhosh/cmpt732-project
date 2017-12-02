library(shiny)
library(plotly)
library(shinydashboard)
library(leaflet)
library(shinycssloaders)

#global
src = read.csv('../input2/percapita/percapitacrime-2015.csv'
                , header = F)
colnames(src) <- c('city', 'state', 'offence_type', 'percapita_crime', 'latitude', 'longitude' )

sidebar <- dashboardSidebar(
  sidebarMenu(id = "sidebarmenu",
              
              menuItem("Section 1", tabName = "tab1", icon = icon("glyphicon glyphicon-usd", lib = "glyphicon")),
              menuItem("Section 2", tabName = "tab2", icon = icon("glyphicon glyphicon-shopping-cart", lib = "glyphicon")),
              menuItem("Section 3", tabName = "tab3", icon = icon("glyphicon glyphicon-shopping-cart", lib = "glyphicon")),
              menuItem("Section 4", tabName = "tab4", icon = icon("glyphicon glyphicon-usd", lib = "glyphicon"))
              # , menuItem("Section 4", tabName = "otif", icon = icon("cube")
              #          ,menuSubItem('Section 4.1',
              #                       tabName = 'otif_tab1',
              #                       icon = icon('truck')),
              #          menuSubItem('Section 4.2',
              #                      tabName = 'otif_tab2',
              #                      icon = icon('sitemap'))
              # )
  )
)

body <- dashboardBody(
  tabItems(
    tabItem(tabName = "tab1",
            tabsetPanel(
              tabPanel("Count",
                       fluidRow(
                         shinycssloaders::withSpinner(plotlyOutput('of_count_plot')),
                         shinycssloaders::withSpinner(plotlyOutput('of_count_race')),
                         shinycssloaders::withSpinner(plotlyOutput('of_by_bias'))
                       )
              ),
              tabPanel("Count2",
                       fluidRow(
                         shinycssloaders::withSpinner(plotlyOutput('of_count_st_plot')),
                         shinycssloaders::withSpinner(plotlyOutput('of_count_race_st')),
                         shinycssloaders::withSpinner(plotlyOutput('top_bias_by_st'))
                       )
              ),
              tabPanel("Heatmap 1",
                       fluidRow(
                         shinycssloaders::withSpinner(plotlyOutput('hunter_vs_hunted'))
                       )
              )
            )
    ), #tabItem
    tabItem(tabName = "tab2",
            tabsetPanel(
              tabPanel("Common Places of Crime ",
                       fluidRow(
                         shinycssloaders::withSpinner(plotlyOutput('of_places_chart')),
                         shinycssloaders::withSpinner(plotlyOutput('of_places_maps'))
                       )
                       
              )
            )
    ), #tabItem
    tabItem(tabName = "tab3",
            tabsetPanel(
              tabPanel("Offence",
                       fluidRow(
                         shinycssloaders::withSpinner(plotlyOutput('tl_offence')),
                         shinycssloaders::withSpinner(plotlyOutput('tl_offence_hm'))
                       )
              ),
              tabPanel("Offender Race",
                       fluidRow(
                         shinycssloaders::withSpinner(plotlyOutput('tl_offender')),
                         shinycssloaders::withSpinner(plotlyOutput('tl_offender_hm'))
                       )
              ),
              tabPanel("Bias",
                       fluidRow(
                         shinycssloaders::withSpinner(plotlyOutput('tl_bias')),
                         shinycssloaders::withSpinner(plotlyOutput('tl_bias_hm'))
                       )
              )
            )
    ), #tabItem
    tabItem(tabName = "tab4",
            tabsetPanel(
              tabPanel("Crime Per 1000",
                       fluidRow(
                         selectInput("s4_ch1","Offence Type", unique(src$offence), width = '95%', multiple = F),
                         shinycssloaders::withSpinner(leafletOutput('leafletPlot1'))
                       )
                       
              )
            )
    )
    
  )#, #tabItems
  #custom css
  # tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "customstyle.css"))
) # dashboardbody

dbHeader <- dashboardHeader()
# dbHeader$children[[2]]$children <-  tags$a(tags$img(src='logo.png',height='auto',width='100%')) # add logo, the .png file is under www dir

ui <- dashboardPage(
  dbHeader,
  sidebar,
  body,
  skin = 'black'
)