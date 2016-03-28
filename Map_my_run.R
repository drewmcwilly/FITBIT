require(XML)
library(plyr)
library(dplyr)
library(stringr)
    xml_file<-"Shellyrun.tcx"
    
    xml_File<-xmlInternalTreeParse(xml_file)

#pull data in from tcx fil
    data<-xmlParse(xml_file)
#put into a list
    xml_data<-xmlToList(data)
#Filter the XML list down to get to the workout data
    temps <- xml_data[["Activities"]][["Activity"]][["Lap"]][["Track"]]
#Transfer content into a data frame
    df2<-ldply(temps, data.frame)

    colnames(df2)<-c("Label","Time","Latitude","Longitude","Meters_Altitude","Meters_Distance")
# Convert columns to numeric    
    df2$Meters_Distance<- as.numeric(as.character(df2$Meters_Distance))
    df2$Meters_Altitude<- as.double(as.character(df2$Meters_Altitude))
    df2$Time<- as.POSIXlt(str_replace_all(as.character(df2$Time), "T", " "))
    df2$Latitude<- as.numeric(as.character(df2$Latitude))
    df2$Longitude<- as.numeric(as.character(df2$Longitude))
#append extra columns
    df2<-mutate(df2, Meters_Interval=Meters_Distance- lag(Meters_Distance, default=0))
    df2<-mutate(df2, Miles=floor(1+(Meters_Distance/1609.344)))
    df2<-mutate(df2,DateTime=as.POSIXct(Time))
    df2<-mutate(df2,Elapsed_Time=(DateTime-DateTime[1])/60)
##Assemble Runmap                                    
    png("plot1.png", width = 800, height = 800)
    center<-as.array(c(df2[1,4],df2[1,3]))
    runmap<-ggmap(get_googlemap(center=center, scale=2, zoom=15), extent="normal")
    runmap+geom_point(aes(x=Longitude, y=Latitude), data=df2, col=ceiling(df2$Meters_Interval)+1, alpha=0.6) 
    dev.off()
##Weather data here:
    weather<-read.csv(url("https://www.wunderground.com/history/airport/KXLL/2016/3/13/DailyHistory.html?reqdb.zip=18104&reqdb.magic=1&reqdb.wmo=99999&format=1"),header=TRUE)