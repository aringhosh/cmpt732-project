library(shiny)
library(plotly)
library(reshape2)
library(leaflet)
library(leaflet.extras)


server <- function(input, output, session) {
  # global vars
  g <- list(
    scope = 'usa',
    projection = list(type = 'albers usa'),
    showlakes = TRUE,
    lakecolor = toRGB('white')
  )
  
  heatmap_colors = c('#FDFFFC', '#7C86BC', '#71f65f', '#f7fa3c', '#eb3c22')
  
  getSortedLabels = function(labels, counts, desc = TRUE){
    sorted_lb = factor(labels, levels = unique(labels)[order(counts, decreasing = desc)])
    return(sorted_lb)
  }
  
  output$of_count_plot <- renderPlotly({
    data = read.csv('input2/offence_by_offence_type/offence_by_offence_type.csv', header = F)
    colnames(data) <- c('type', 'state', 'count')
    
    data.byType <- aggregate(count ~ type, data, sum)
    data.byType$type = getSortedLabels(data.byType$type, data.byType$count, F) # sort
    
    #by offence type
    plot_ly(data.byType, x = ~count, y = ~type, 
            type = 'bar',
            color = ~ifelse(count > median(count), 'high crime', 'low crime'),
            colors = c('#DB5461', '#4F8687') ,
            orientation = 'h') %>% layout(margin = list(l = 220, t = 50)
                                          , title = 'Offence Types'
                                          , hovermode = "closest"
                                          , yaxis = list(title = ''), xaxis = list(title = 'No. Of Incidents'))
    
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
        title = 'Crime Incident Reports (2011-15)'
        , margin = list(t = 50)
        , geo = g
      )
  })
  
  output$of_count_race <- renderPlotly({
    data = read.csv('../input2/offence_by_offenders_race/offence_by_offenders_race.csv', header = F)
    colnames(data) <- c('state', 'race', 'count')
    data = aggregate(count ~ race, data, sum)
    data$race = getSortedLabels(data$race, data$count, F)
    
    #by offender race group
    plot_ly(data, x = ~count, y = ~race, 
            type = 'bar',
            color = ~race,
            colors = RColorBrewer::brewer.pal(5, "Blues")) %>% 
      layout(margin = list(l = 250, t = 50)
             , title = 'Offenders : Who Are We?'
             , yaxis = list(title = ''), xaxis = list(title = 'No. Of Incidents'))
  })
  
  output$of_count_race_st <- renderPlotly({
    data = read.csv('../input2/offence_by_offenders_race/offence_by_offenders_race.csv', header = F)
    colnames(data) <- c('state', 'race', 'count')
    
    # data$state = getSortedLabels(data$state, data$count)
    
    plot_ly(data, x = ~state, y = ~count, type = 'bar', color = ~race, colors = 'Reds') %>%
      layout(barmode = 'stack'
             , title = 'Offender Group By State'
             , yaxis = list(title = 'incidents'), xaxis = list(title = '')
             , margin = list(t = 50))
  })
  
  output$of_by_bias <- renderPlotly({
    data = read.csv('../input2/offence_by_victim_by_state/offence_by_victim_by_state.csv', header = F)
    colnames(data) <- c('bias', 'state', 'count')
    data = aggregate(count ~ bias, data, sum)
    data$bias = getSortedLabels(data$bias, data$count, F)
    
    #by bias
    plot_ly(data, x = ~count, y = ~bias, type = 'bar', 
            color = ~ifelse(count > median(count), 'high crime', 'low crime'),
            colors = c('#DB5461', '#4F8687')) %>% 
      layout(margin = list(l = 275, t = 50)
             , title = 'Who Are We Against?'
             , yaxis = list(title = ''), xaxis = list(title = 'No. Of Incidents'))
  })
  
  output$top_bias_by_st <- renderPlotly({ 
    data = read.csv('../input2/offence_by_victim_by_state/offence_by_victim_by_state.csv', header = F)
    colnames(data) <- c('bias', 'state', 'count')
    data1 = aggregate(count ~ state, data, max)
    data1 = merge(data1, data, by = c('state', 'count'))
    data1$state = getSortedLabels(data1$state, data1$count)
    
    plot_ly(data1, x = ~state, y = ~count, 
            type = 'bar',
            colors = 'Blues',
            color = ~as.character(bias)
            , marker = list(
              line = list(color = 'rgb(8,48,107)',
                          width = 0.7))
            ) %>%
      layout(
        title = 'Dominant Bias For Each State'
        , margin = list(t =50)
        , yaxis = list(title = 'incidents'), xaxis = list(title = '')
      )
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
    data = aggregate(count~location, data, sum)
    data$location = getSortedLabels(data$location, data$count, F)
    
    #count by offence by location country wide
    plot_ly(data , x = ~count, y = ~location, type = 'bar'
            , color = ~ifelse(count > mean(count), 'above nat avg', 'below nat avg') 
              , colors = RColorBrewer::brewer.pal(2, "RdGy")
            ,marker = list(line = list(color = 'rgb(8,48,107)', width = 0.5))
            ) %>%
      layout(margin = list(l = 250, t = 50)
             , title = 'Top Places Of Offence'
             , yaxis = list(title = ''), xaxis = list(title = 'incidents')
             )
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
    
    data1 = aggregate(count ~ offence, data, sum)
    top10_types =as.character( data1[order(-data1$count),][1:10,1] )
    
    data = data[data$offence %in% top10_types, ]
    data$date = paste0(data$year,data$month,'01')
    data$date= as.Date(data$date, '%Y%b%d')
    
    data = aggregate(count ~ date + offence, data, sum)
    
    #reshape data- 
    data1 <- reshape(data, idvar = "date", timevar = "offence", direction = "wide")
    data1[is.na(data1)] <- 0 # TODO may be we want to change the colnames here
    y_cols = colnames(data1[2:ncol(data1)])
    y_cols <- substr(y_cols,7, nchar(y_cols))
    
    p <- plot_ly(y=data1[,2], x=data1$date , type="scatter", mode="markers+lines", name = y_cols[1])
    for(i in 3:ncol(data1)){
      my_y= data1[,i]
      p <-add_trace(p, y= my_y, x=data1$date , type="scatter", mode="markers+lines", name = y_cols[i-1] )
    }
    
    p %>% layout(hovermode = 'x', title = 'Top 10 Crimes Over Year', margin = list(t = 50))
  })
  
  output$tl_offence_hm <- renderPlotly({
    data = read.csv('../input2/YR_MM_offence_type/YR_MM_offence_type.csv'
                    , header = F)
    colnames(data) <- c('year', 'month', 'offence', 'count')
    
    #offence count by year
    data1 = aggregate(count ~ month + offence, data, sum)
    #reshape data wide- 
    data1 <- reshape(data1, idvar = "month", timevar = "offence", direction = "wide")
    data1[is.na(data1)] <- 0
    data1 <- data1[order(match(data1$month, month.abb)), ] #order month col in the correct chronological way
    y_cols <- paste0(substr(colnames(data1[,-1]), 7 , length(colnames(data1[,-1]))), " ")
    
    d_mat <- t(as.matrix.data.frame(data1[,-1]))
    
    plot_ly(x = data1$month, y = y_cols, z = d_mat, type ='heatmap'
            , colors = colorRamp(heatmap_colors)
            )  %>%
      layout(margin = list(l = 230)
             , yaxis = list(categoryorder = "trace")
             , xaxis = list(categoryorder = "trace")
             )
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
    # clear the map 
    map <- leafletProxy("leafletPlot1") %>% clearMarkerClusters()
    
    if(offence_type == 'select one...') {
      print('match')
      return()
    }
    
    filteredData <- per.capita.2015[per.capita.2015$offence_type == offence_type,]
    
    map %>%
      addMarkers( data = filteredData,
                  clusterOptions = markerClusterOptions(),
                  popup = ~paste0("<b>Offence</b>: ", offence_type,
                                  "<br><b>City: </b>",city,
                                  "<br><b>State: </b>",state,
                                  "<br><b>Per Capita Crime:</b>", format(percapita_crime, digits = 3))
      )
    
  })
  
  
  # tab 4 part 2 (heat map) ---- 
  
  hm_data = read.csv('../input2/percapita/all_crime_by_year.csv'
                     , header = F)
  colnames(hm_data) <- c('city', 'state', 'offence_type', 'count', 'latitude', 'longitude', 'year' )
  
  output$leafletPlot2 <- renderLeaflet({
    leaflet() %>% addProviderTiles(providers$CartoDB.Positron) %>% setView( -97, 37, zoom = 4 )
  })
  
  observe({
    
    yr = input$s4_ch2
    fd = hm_data[hm_data$year == yr, ]
    
    leafletProxy("leafletPlot2") %>% clearHeatmap() %>% addHeatmap(data = fd, intensity = ~count, blur = 15, radius = 8)
    
  })
  
  
  
} # server - top level


