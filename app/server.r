library(shiny)
library(plotly)
library(reshape2)
library(leaflet)


server <- function(input, output, session) {
  # global vars
  g <- list(
    scope = 'usa',
    projection = list(type = 'albers usa'),
    showlakes = TRUE,
    lakecolor = toRGB('white')
  )
  
  
  output$of_count_plot <- renderPlotly({
    data = read.csv('input2/offence_by_offence_type/offence_by_offence_type.csv', header = F)
    colnames(data) <- c('type', 'state', 'count')
    
    data.byType <- aggregate(count ~ type, data, sum)
    
    #by offence type
    plot_ly(data.byType, x = ~count, y = ~type, 
            type = 'bar',
            color = ~ifelse(count > median(count), 'high crime', 'low crime'),
            colors = c('#DB5461', '#4F8687') ,
            name = 'plot1.1', orientation = 'h') %>% layout(margin = list(l = 220))
    
  })
  
  output$of_count_st_plot <- renderPlotly({
    data = read.csv('input2/offence_by_offence_type/offence_by_offence_type.csv', header = F)
    colnames(data) <- c('type', 'state', 'count')
    data.byState <- aggregate(count ~ state, data, sum)
    
    plot_geo(data.byState, locationmode = 'USA-states') %>%
      add_trace(
        z = ~count, locations = ~state,
        color = ~count, 
        colors = 'Reds' #c('#4F8687', '#DB5461')
      ) %>%
      layout(
        title = 'Offence By Count (2011-15)',
        geo = g
      )
  })
  
  output$of_count_race <- renderPlotly({
    data = read.csv('../input2/offence_by_offenders_race/offence_by_offenders_race.csv', header = F)
    colnames(data) <- c('race', 'state', 'count')
    
    #by offender race group
    plot_ly(data, x = ~race, y = ~count, 
            type = 'bar',
            color = ~race,
            colors = 'Blues',
            name = 'plot1.1' ) 
  })
  
  output$of_count_race_st <- renderPlotly({
    data = read.csv('../input2/offence_by_offenders_race/offence_by_offenders_race.csv', header = F)
    colnames(data) <- c('race', 'state', 'count')
    plot_ly(data, x = ~state, y = ~count, type = 'bar', name = 'plot2.1', color = ~race)
  })
  
  output$of_by_bias <- renderPlotly({
    data = read.csv('../input2/offence_by_victim_by_state/offence_by_victim_by_state.csv', header = F)
    colnames(data) <- c('bias', 'state', 'count')
    
    #by bias
    plot_ly(data, x = ~count, y = ~bias, type = 'bar', 
            color = ~ifelse(count > median(count), 'high crime', 'low crime'),
            colors = c('#DB5461', '#4F8687') ,
            name = 'plot2.1') %>% layout(margin = list(l = 250))
  })
  
  output$top_bias_by_st <- renderPlotly({ 
    data = read.csv('../input2/offence_by_victim_by_state/offence_by_victim_by_state.csv', header = F)
    colnames(data) <- c('bias', 'state', 'count')
    data1 = aggregate(count ~ state, data, max)
    data1 = merge(data1, data, by = c('state', 'count'))
    
    plot_ly(data1, x = ~state, y = ~count, 
            type = 'bar', name = 'plot2.1', 
            color = ~as.character(bias))
  })
  
  output$hunter_vs_hunted <- renderPlotly({
    data = read.csv('../input2/heatmap/offender+victim_count.csv', header = F)
    colnames(data) <- c('victim', 'race', 'count')
    
    # reshape the data to long format
    w <- reshape(data, idvar = "race", timevar = "victim", direction = "wide")
    w[is.na(w)] <- 0 # TODO may be we want to change the colnames here
    d_mat <- t(as.matrix.data.frame(w[,-1]))
    y_cols <- paste0(substr(colnames(w[,-1]), 7 , length(colnames(w[,-1]))), " ")
    plot_ly(x = w$race, 
            y = y_cols, 
            z = d_mat, type ='heatmap', 
            colors = colorRamp(c("#fdfffc", "#FF9F1C", "#E71D36")))  %>%
      layout(yaxis = list(categoryorder = "trace"), xaxis = list(categoryorder = "trace")) %>%
      layout(margin = list(l = 200))
  })
  
  output$of_places_chart <- renderPlotly({
    data = read.csv('../input2/offence_by_location_by_state/offence_by_location_by_state.csv'
                    , header = F)
    colnames(data) <- c('offenceName', 'location', 'state', 'count')
    
    #count by offence by location country wide
    plot_ly(aggregate(count~location, data, sum), x = ~count, y = ~location, type = 'bar', name = 'plot2.1') %>%
      layout(margin = list(l = 250))
  })
  
  output$of_places_maps <- renderPlotly({
    data = read.csv('../input2/offence_by_location_by_state/offence_by_location_by_state.csv'
                    , header = F)
    colnames(data) <- c('offenceName', 'location', 'state', 'count')
    
    # location = School--elementary; state= all
    lots = data[data$location == 'School--elementary/secondary',]
    lots = aggregate(count ~ state, lots, sum)
    p0 <- plot_geo(lots, locationmode = 'USA-states', showscale=FALSE ) %>%
      add_trace(
        z = ~count, locations = ~state,
        color = ~count,
        colors = 'Blues'
      ) %>%
      layout(
        geo = g
      )
    
    # location = residence; state= all
    home = data[data$location == 'Residence/home',]
    home = aggregate(count ~ state, home, sum)
    p1 <- plot_geo(home, locationmode = 'USA-states', showscale=FALSE ) %>%
      add_trace(
        z = ~count, locations = ~state,
        color = ~count,
        colors = 'Reds' #c('#4F8687', '#DB5461')
      ) %>%
      layout(
        geo = g
      )
    
    # location = school; state= all
    school = data[data$location == 'School/college',]
    school = aggregate(count ~ state, school, sum)
    p2 <- plot_geo(school, locationmode = 'USA-states', showscale=FALSE ) %>%
      add_trace(
        z = ~count, locations = ~state,
        color = ~count,
        colors = 'Purples' #c('#4F8687', '#DB5461')
      ) %>%
      layout(
        geo = g
      )
    
    # location = Highway/road/alley; state= all
    highway = data[data$location == 'Highway/road/alley',]
    highway = aggregate(count ~ state, highway, sum)
    p3 <- plot_geo(highway, locationmode = 'USA-states', showscale=FALSE ) %>%
      add_trace(
        z = ~count, locations = ~state,
        color = ~count,
        colors = c('#fffeff', '#B40F16')
      ) %>%
      layout(
        geo = g
      )
    
    #subplot merge
    subplot(p0, p1, p2, p3, nrows = 2) %>%
      layout(title = "Crimes By Locations") %>%
      layout(annotations = list(
        list(x = 0.2 , y = 1.00, text = "Elementary School", showarrow = F, xref='paper', yref='paper'),
        list(x = 0.8 , y = 1.0, text = "Residence", showarrow = F, xref='paper', yref='paper'),
        list(x = 0.15 , y = -.04, text = "School/ Universities", showarrow = F, xref='paper', yref='paper'),
        list(x = 0.8 , y = -.04, text = "Highway/Roads", showarrow = F, xref='paper', yref='paper'))
      )
  })
  
  #tab 3 ####
  output$tl_offence <- renderPlotly({
    data = read.csv('../input2/YR_MM_offence_type/YR_MM_offence_type.csv'
                    , header = F)
    colnames(data) <- c('year', 'month', 'offence', 'count')
    
    #offence count by year
    data1 = aggregate(count ~ year + offence, data, sum)
    
    #reshape data- 
    data1 <- reshape(data1, idvar = "year", timevar = "offence", direction = "wide")
    data1[is.na(data1)] <- 0 # TODO may be we want to change the colnames here
    trace_names <- colnames(data1[,-1])
    data1$year = as.character(data1$year) #factorize years for x axis
    
    p <- plot_ly(y=data1[,2], x=data1$year , type="scatter", mode="markers+lines", name = trace_names[1])
    for(i in 3:ncol(data1)){
      my_y= data1[,i]
      p <-add_trace(p, y= my_y, x=data1$year , type="scatter", mode="markers+lines", name = trace_names[i-1] )
    }
    
    p
  })
  output$tl_offence_hm <- renderPlotly({
    data = read.csv('../input2/YR_MM_offence_type/YR_MM_offence_type.csv'
                    , header = F)
    colnames(data) <- c('year', 'month', 'offence', 'count')
    
    #offence count by year
    data1 = aggregate(count ~ month + offence, data, sum)
    #reshape data wide- 
    data1 <- reshape(data1, idvar = "month", timevar = "offence", direction = "wide")
    data1[is.na(data1)] <- 0 # TODO may be we want to change the colnames here
    data1 <- data1[order(match(data1$month, month.abb)), ] #order month col in the correct chronological way
    y_cols <- paste0(substr(colnames(data1[,-1]), 7 , length(colnames(data1[,-1]))), " ")
    
    d_mat <- t(as.matrix.data.frame(data1[,-1]))
    plot_ly(x = data1$month, y = y_cols, z = d_mat, type ='heatmap', colors = colorRamp(c("#fdfffc", "#FF9F1C", "#E71D36")))  %>%
      layout(yaxis = list(categoryorder = "trace"), xaxis = list(categoryorder = "trace"))
    
  })
  
  output$tl_offender <- renderPlotly({
    data = read.csv('../input2/YR_MM_offender/YR_MM_offender.csv'
                    , header = F)
    colnames(data) <- c('year', 'month', 'offender', 'count')
    
    #offender count by year
    data1 = aggregate(count ~ year + offender, data, sum)
    
    #reshape data- 
    data1 <- reshape(data1, idvar = "year", timevar = "offender", direction = "wide")
    data1[is.na(data1)] <- 0 # TODO may be we want to change the colnames here
    trace_names <- colnames(data1[,-1])
    data1$year = as.character(data1$year) #factorize years for x axis
    
    p <- plot_ly(y=data1[,2], x=data1$year , type="scatter", mode="markers+lines", name = trace_names[1])
    for(i in 3:ncol(data1)){
      my_y= data1[,i]
      p <-add_trace(p, y= my_y, x=data1$year , type="scatter", mode="markers+lines", name = trace_names[i-1] )
    }
    p
    
  })
  output$tl_offender_hm <- renderPlotly({
    data = read.csv('../input2/YR_MM_offender/YR_MM_offender.csv'
                    , header = F)
    colnames(data) <- c('year', 'month', 'offender', 'count')
    
    #offender count by year
    data1 = aggregate(count ~ month + offender, data, sum)
    #reshape data wide- 
    data1 <- reshape(data1, idvar = "month", timevar = "offender", direction = "wide")
    data1[is.na(data1)] <- 0 # TODO may be we want to change the colnames here
    data1 <- data1[order(match(data1$month, month.abb)), ] #order month col in the correct chronological way
    y_cols <- paste0(substr(colnames(data1[,-1]), 7 , length(colnames(data1[,-1]))), " ")
    
    d_mat <- t(as.matrix.data.frame(data1[,-1]))
    plot_ly(x = data1$month, y = y_cols, z = d_mat, type ='heatmap', colors = colorRamp(c("#fdfffc", "#FF9F1C", "#E71D36")))  %>%
      layout(yaxis = list(categoryorder = "trace"), xaxis = list(categoryorder = "trace"))
    
  })
  
  output$tl_bias <- renderPlotly({
    data = read.csv('../input2/YR_MM_victims/YR_MM_victims.csv'
                    , header = F)
    colnames(data) <- c('year', 'month', 'victims', 'count')
    
    #victims count by year
    data1 = aggregate(count ~ year + victims, data, sum)
    
    #reshape data- 
    data1 <- reshape(data1, idvar = "year", timevar = "victims", direction = "wide")
    data1[is.na(data1)] <- 0 # TODO may be we want to change the colnames here
    trace_names <- colnames(data1[,-1])
    data1$year = as.character(data1$year) #factorize years for x axis
    
    p <- plot_ly(y=data1[,2], x=data1$year , type="scatter", mode="markers+lines", name = trace_names[1])
    for(i in 3:ncol(data1)){
      my_y= data1[,i]
      p <-add_trace(p, y= my_y, x=data1$year , type="scatter", mode="markers+lines", name = trace_names[i-1] )
    }
    p
    
  })
  output$tl_bias_hm <- renderPlotly({
    
    data = read.csv('../input2/YR_MM_victims/YR_MM_victims.csv'
                    , header = F)
    colnames(data) <- c('year', 'month', 'victims', 'count')
    
    #victims count by year
    data1 = aggregate(count ~ month + victims, data, sum)
    #reshape data wide- 
    data1 <- reshape(data1, idvar = "month", timevar = "victims", direction = "wide")
    data1[is.na(data1)] <- 0 # TODO may be we want to change the colnames here
    data1 <- data1[order(match(data1$month, month.abb)), ] #order month col in the correct chronological way
    y_cols <- paste0(substr(colnames(data1[,-1]), 7 , length(colnames(data1[,-1]))), " ")
    
    d_mat <- t(as.matrix.data.frame(data1[,-1]))
    plot_ly(x = data1$month, y = y_cols, z = d_mat, type ='heatmap', colors = colorRamp(c("#fdfffc", "#FF9F1C", "#E71D36")))  %>%
      layout(yaxis = list(categoryorder = "trace"), xaxis = list(categoryorder = "trace"))
    
  })
  
  #tab 4 ----
  
  map1 <- leaflet() %>% addTiles(
    urlTemplate = "//{s}.tiles.mapbox.com/v3/jcheng.map-5ebohr46/{z}/{x}/{y}.png",
    attribution = 'Maps by <a href="http://www.mapbox.com/">Mapbox</a>'
  )
  
  output$leafletPlot1 <- renderLeaflet({
    leaflet() %>% addTiles(
      urlTemplate = "//{s}.tiles.mapbox.com/v3/jcheng.map-5ebohr46/{z}/{x}/{y}.png",
      attribution = 'Maps by <a href="http://www.mapbox.com/">Mapbox</a>'
    ) %>% setView(-97, 37, zoom = 4)
  })
  
  #global 
  # per capita crime
  per.capita.2015 = read.csv('../input2/percapita/percapitacrime-2015.csv'
                  , header = F)
  colnames(per.capita.2015) <- c('city', 'state', 'offence_type', 'percapita_crime', 'latitude', 'longitude' )
  
  observe({
    offence_type = input$s4_ch1
    filteredData <- per.capita.2015[per.capita.2015$offence_type == offence_type,]
    
    leafletProxy("leafletPlot1") %>% clearMarkerClusters() %>%
      addMarkers( data = filteredData,
                  clusterOptions = markerClusterOptions(),
                  popup = ~paste0("<b>Offence</b>: ", offence_type,
                                  "<br><b>City: </b>",city,
                                  "<br><b>State: </b>",state,
                                  "<br><b>Per Capita Crime:</b>", format(percapita_crime, digits = 3))
      )
    
  })
  
} # server - top level


