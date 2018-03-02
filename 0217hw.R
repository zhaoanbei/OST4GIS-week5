setwd("C:/Users/zhaoa/Documents/GitHub/MUSA-620-Week-5")
library(RPostgreSQL)
library(sf)
library(postGIStools)
library(tidyverse)
library(viridis)
library(classInt)
library(ggplot2)

myTheme <- function() {
  theme_void() + 
    theme(
      text = element_text(size = 7),
      plot.title = element_text(size = 14, color = "#eeeeee", hjust = 0, vjust = 0, face = "bold"), 
      plot.subtitle = element_text(size = 12, color = "#cccccc", hjust = 0, vjust = 0),
      axis.ticks = element_blank(),
      panel.grid.major = element_line(colour = "#333333"),
      panel.background = element_rect(fill = "#333333"),
      plot.background = element_rect(fill = "#333333"),
      legend.direction = "vertical", 
      legend.position = "right",
      plot.margin = margin(0, 0, 0, 0, 'cm'),
      legend.key.height = unit(1, "cm"), legend.key.width = unit(0.4, "cm"),
      legend.title = element_text(size = 12, color = "#eeeeee", hjust = 0, vjust = 0, face = "bold"),
      legend.text = element_text(size = 8, color = "#cccccc", hjust = 0, vjust = 0)
    ) 
}

drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "spatialdb",
                 host = "127.0.0.1", port = 5432,
                 user = "postgres", password = 'zab')





####Skip from####
#data cleaning(omit na) and filter "rape" type
#pojected on GIS, no need to filter into philly booundary
crime <- read.csv("crime.csv")
crime1<-na.omit(crime)
crime2<-crime1[crime1$Text_General_Code == "Rape", ]
write.csv(crime2,"crime1.csv")

crime2=read.csv("crime1.csv")
crimeSF <- st_as_sf(crime2, coords = c("Lon", "Lat"), crs = 4326)
crimeSF <- st_transform(crimeSF, 3785)
plot(crimeSF)

st_write_db(con, crimeSF, "crime", drop=T)
#read shp
streetSF <- st_read('Street_Centerline.shp', stringsAsFactors = FALSE)
streetSF <- st_transform(streetSF, 3785)
streetSF <- rename(streetSF, segid = SEG_ID)
st_write_db(con, streetSF, "streetsf", drop = TRUE)
dbGetQuery(con, "SELECT * FROM geometry_columns")



# attach each crime to nearest street
dbGetQuery(con, "CREATE INDEX crime_gix ON crime USING GIST (wkb_geometry)")
dbGetQuery(con, "CREATE INDEX street_gix ON streetsf USING GIST (wkb_geometry)")



####skip to ####

#DISTINCT ON 
spatialQuery <- paste0("SELECT DISTINCT ON (c.wkb_geometry) c.*, s.segid, ",
                       "ST_Distance(c.wkb_geometry, s.wkb_geometry) AS distance ",
                       "FROM crime AS c, streetsf AS s ",
                       "WHERE ST_Distance(c.wkb_geometry, s.wkb_geometry) < 1000",
                       "ORDER BY c.wkb_geometry, ST_Distance(c.wkb_geometry, s.wkb_geometry) ASC")

Count <- st_read_db(con, query=spatialQuery, geom_column='wkb_geometry')
st_write(Count, "count.shp")
count <- st_read('count.shp')
countSF <- st_transform(count, 3785)
st_write_db(con, countSF, "count", drop = TRUE)
dbGetQuery(con, "SELECT * FROM geometry_columns")

# count the number of crimes per street
street = st_read_db(con, query = "SELECT * FROM streetsf")
crime = st_read_db(con, query = "SELECT * FROM count")

spatialQuery <- paste0("SELECT s.wkb_geometry as geom, s.segid, COUNT(c.wkb_geometry) AS cnt  ",
                       "FROM streetsf AS s, count AS c ",
                       "WHERE c.segid=s.segid ",
                       "GROUP BY (s.wkb_geometry, s.segid) ")
Count1 <- st_read_db(con, query=spatialQuery, geom_column='geom')

#sqlCommand1 <- paste0("SELECT s.segid,COUNT(c.*) AS num ",
#                      "FROM count AS c ",
#                      "JOIN streetsf AS s ",
#                      "ON c.segid = s.segid ",
#                      "GROUP BY s.segid ")

#count_c_s<-dbGetQuery(con, spatialQuery)
####
ty <- read.csv("data-1519008802259.csv")
Count2<- as.data.frame(Count1)
mr<- merge(street, ty, all.x=T)

#dbGetQuery(con, "SELECT UpdateGeometrySRID('phillysf1','wkb_geometry',3785)")
phillySF <- st_read('C:/Users/zhaoa/Documents/GitHub/MUSA-620-Week-1/census-tracts-philly.shp', stringsAsFactors = FALSE)
phillySF <- st_as_sf(phillySF, coords = c("Lon", "Lat"), crs = 4326)
phillySF <- st_transform(phillySF, 3785)
st_write_db(con, phillySF, "phillysf", drop=T)



ggplot()+
  geom_sf(data=phillySF, fill= "#555555", color="black")+
  geom_sf(data = mr, aes(color = cnt)) +
  scale_color_gradient(low="blue",high="blue",na.value = "yellow") +
  scale_fill_discrete(guide=FALSE)+
  labs(title = "_Non-Rape Streets",
       subtitle = "Philadelphia Crime Data in Ten Years",
       caption = "OpenDataPhilly") +
  myTheme()


mr$category[mr$cnt <= 1] <- "low"
mr$category[mr$cnt > 1 & mr$cnt <= 2] <- "middle"
mr$category[mr$cnt > 2] <- "high"

ggplot()+
  geom_sf(data=phillySF, fill= "#555555", color="#555555")+
  geom_sf(data = mr, aes(color = category)) +
  labs(title = "_Rape Frequency for Each Streets",
       subtitle = "Philadelphia Crime Data in Ten Years",
       caption = "OpenDataPhilly",
       # remove the caption from the legend
       fill = "Crime(Rape)") +
  myTheme()

library(gridExtra)
library(grid)
library(lattice)
grid.arrange(p1, p2, ncol=2)
