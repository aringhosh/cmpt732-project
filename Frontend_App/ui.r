library(shiny)
library(plotly)
library(shinydashboard)
library(leaflet)
library(shinycssloaders)

#global
src = read.csv('input2/percapita/percapitacrime-2015.csv'
                , header = F)
colnames(src) <- c('city', 'state', 'offence_type', 'percapita_crime', 'latitude', 'longitude' )

# print(unique(src$offence_type))


sidebar <- dashboardSidebar(
  sidebarMenu(id = "sidebarmenu",
              
              menuItem("General Crime Trends 2011-15", tabName = "tab1", icon = icon("bar-chart")),
              menuItem("Places", tabName = "tab2", icon = icon("building")),
              menuItem("Crime Timelines", tabName = "tab3", icon = icon("line-chart")),
              menuItem("Dynamic Geo Map", tabName = "otif", icon = icon("map")
                       ,menuSubItem('Geo Clustered Crime Map',
                                    tabName = 'map1',
                                    icon = icon('map-marker')),
                       menuSubItem('Crime Intensity',
                                   tabName = 'map2',
                                   icon = icon('globe'))
              )
  )
)

body <- dashboardBody(
  tabItems(
    tabItem(tabName = "tab1",
            tabsetPanel(
              tabPanel("Crime View 1",
                       fluidRow(
                         shinycssloaders::withSpinner(plotlyOutput('of_count_plot')),
                         tags$br(),
                         shinycssloaders::withSpinner(plotlyOutput('of_count_race')),
                         tags$br(),
                         shinycssloaders::withSpinner(plotlyOutput('of_by_bias'))
                       )
              ),
              tabPanel("Crime View 2",
                       fluidRow(
                         shinycssloaders::withSpinner(plotlyOutput('of_count_st_plot')),
                         shinycssloaders::withSpinner(plotlyOutput('of_count_race_st')),
                         shinycssloaders::withSpinner(plotlyOutput('top_bias_by_st'))
                       )
              ),
              tabPanel("Who Against Whom?",
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
    tabItem(tabName = "map1",
            tabsetPanel(
              tabPanel("Per capita crime 2015",
                       fluidRow(
                         selectInput("s4_ch1","Offence Type", 
                                     c('select one...', unique(as.character(src$offence_type))), 
                                     width = '95%', multiple = F),
                         shinycssloaders::withSpinner(leafletOutput('leafletPlot1',  height = 600))
                       )
                       
              )
            )
    ),
    tabItem(tabName = "map2",
            tabsetPanel(
              tabPanel("Crimes Trends by year",
                       fluidRow(
                         # selectInput("s4_ch2","Year", c('2011','2012','2013','2014','2015'), width = '95%', multiple = F),
                         sliderInput("s4_ch2","Year", value = 2011, min = 2011, max = 2015, step = 1, 
                                     animate = animationOptions(interval = 2000, loop = TRUE), width = '95%'),
                         shinycssloaders::withSpinner(leafletOutput('leafletPlot2'))
                       )
                       
              )
            )
    )
    
  )#, #tabItems
  #custom css
  # tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "customstyle.css"))
) # dashboardbody

dbHeader <- dashboardHeader(
  title = "CMPT 732 - US Crime"
)
# dbHeader$children[[2]]$children <-  tags$a(tags$img(src='logo.png',height='auto',width='100%')) # add logo, the .png file is under www dir

ui <- dashboardPage(
  dbHeader,
  sidebar,
  body,
  skin = 'black'
)