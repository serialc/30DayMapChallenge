#### Connect to MariaDB ####
#install.packages("RMariaDB")
library(RMariaDB)

# connection
con <- dbConnect(RMariaDB::MariaDB(), user='cyrille', password='')
# select my database
dbSendQuery(con, 'use testing')
# show the tables in the DB
res <- dbSendQuery(con, 'show tables')
df <- dbFetch(res) # fetches all, otherwise n=# to limit
dbClearResult(res)
print(df)

#### Find out from what date the bus started using the highway ####
hwylats = c(49.5117, 49.513)
hwylngs = c(5.953, 5.955)

res <- dbSendQuery(con, paste('SELECT DATE(dt) as date FROM busmov WHERE ',
      'lat > ', hwylats[1], 'AND', 'lat < ', hwylats[2], 'AND',
      'lng > ', hwylngs[1], 'AND', 'lng < ', hwylngs[2], ' GROUP BY DATE(dt)'
      ))
hwy_dates <- dbFetch(res) # fetches all, otherwise n=# to limit
dbClearResult(res)
print(hwy_dates)

first_hwy_date = hwy_dates$date[1]

#### Retrieve the points for the area and period of interest ####

# Get data in bounds
lats = c(49.5045, 49.51352)
lngs = c(5.94519, 5.96511)

res <- dbSendQuery(con, paste('SELECT DATE(dt) as date, tripcode, lat, lng FROM busmov WHERE ',
                              'lat > ', lats[1], 'AND', 'lat < ', lats[2], 'AND',
                              'lng > ', lngs[1], 'AND', 'lng < ', lngs[2], 'AND',
                              'DATE(dt) >= \'', hwy_dates$date[1], '\'' 
))
llpoints <- dbFetch(res) # fetches all, otherwise n=# to limit
nrow(llpoints)
dbClearResult(res)

plot(llpoints$lng, llpoints$lat)

#### Make the points nicer by categorizing them ####

# Let's make the data geographic - project it
library(sf)

pts <- st_as_sf(llpoints, coords = c('lng', 'lat'), crs=4326)
tpts <- st_transform(pts, crs=2169)

svg(filename = "rought_output.svg", width = 8, height = 6)

plot(tpts$geometry, col=adjustcolor(pts$tripcode+2, alpha.f = 0.2), pch=19, cex=0.4)

dev.off()
