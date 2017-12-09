library(httr)
library(jsonlite)

key = '90f1e97b109d6a'
format = 'json'
countrycodes= 'us'
url = 'http://locationiq.org/v1/search.php'

input =read.csv('Data/cities.csv', stringsAsFactors = F)
out  = data.frame(address = character(), latitude = numeric(), longitude = numeric(), comment = character())

for(i in 1:nrow(input)){
  print(paste(i,'of', nrow(input)))
  
  q = paste0(input$CITY[i],', ',input$STATECOD[i])
  qry = as.list(data.frame (key, format, q, countrycodes, stringsAsFactors = F))

  r <- GET(url, query = qry)
  response = content(r, "text", encoding = 'UTF-8')
  df <- fromJSON(response)
    
  if(length(df) >0){
    if(is.null(df$error))
      out = rbind(out, data.frame(q, df$lat[1], df$lon[1], 'OK'))
    else
      # out = rbind(out, data.frame(q, -1, -1, df$error))
      print(paste('Error processing', df$error))
  }else{
    # out = rbind(out, data.frame(q, -1, -1, 'ERR'))
    print(paste('record not found', q))
  }
  
  Sys.sleep(1) #rate limited
}

write.csv(out, 'cities.csv', row.names = F)
