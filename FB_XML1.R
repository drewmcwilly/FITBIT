    require(XML)
    library(plyr)
    library(dplyr)
    library(stringr)
    library(ggmap)
    source('time_match.R')
    xml_file<-"2041648905.tcx"
    
    xml_File<-xmlInternalTreeParse(xml_file)
    
#pull data in from tcx fil
    data<-xmlParse(xml_file)
#put into a list
    xml_data<-xmlToList(data)
#Filter the XML list down to get to the workout data
    temps <- xml_data[["Activities"]][["Activity"]][["Lap"]][["Track"]]
#Transfer content into a data frame
    df2<-ldply(temps, data.frame)

    colnames(df2)<-c("Label","Time","Latitude","Longitude","Meters_Altitude","Meters_Distance","Heartrate")
# Convert columns to numeric    
    df2$Meters_Distance<- as.numeric(as.character(df2$Meters_Distance))
    df2$Heartrate<- as.numeric(as.character(df2$Heartrate))
    df2$Meters_Altitude<- as.double(as.character(df2$Meters_Altitude))
    df2$Time<- as.POSIXlt(str_replace_all(as.character(df2$Time), "T", " "))
    df2$Latitude<- as.numeric(as.character(df2$Latitude))
    df2$Longitude<- as.numeric(as.character(df2$Longitude))
#append extra columns
    df2<-mutate(df2, Meters_Interval=Meters_Distance- lag(Meters_Distance, default=0))
    df2<-mutate(df2, Miles=floor(1+(Meters_Distance/1609.344)))
    df2<-mutate(df2,DateTime=as.POSIXct(Time))
    df2<-mutate(df2,Elapsed_Time=(DateTime-DateTime[1])/60)
    vmi<-kmeans(df2$Meters_Interval,5)
    vhr<-kmeans(df2$Heartrate,5)
    df2<-mutate(df2,Speed_cluster=(vmi$cluster))
    df2<-mutate(df2,hr_cluster=(vhr$cluster))
    df2$Speed_cluster<- as.numeric(as.character(df2$Speed_cluster))
    df2$hr_cluster<- as.numeric(as.character(df2$hr_cluster))
##Assemble Runmap
    md_Rw<-round(nrow(df2)/2,0)
    dd<-format(df2[1,10], "%m%d%Y")
    png(paste(dd,".png", sep=""), width = 800, height = 800)
    center<-as.array(c(df2[md_Rw,4],df2[md_Rw,3]))
    runmap<-ggmap(get_googlemap(center=center, scale=2, zoom=15), extent="normal")
    runmap+geom_point(aes(x=Longitude, y=Latitude), data=df2, col=(df2$Speed_cluster), alpha=0.6) 
    dev.off()
##Weather data here:
    res <- revgeocode(center, output="more")
    zCode<-res$postal_code
    wd<-format(df2[1,10],"%Y%/%m%/%d")
    w_url<-paste("https://www.wunderground.com/history/airport/KXLL/",wd,"/DailyHistory.html?reqdb.zip=",zCode,"&reqdb.magic=1&reqdb.wmo=99999&format=1", sep="")
    weather<-read.csv(url(w_url))
##Clean up weather data
    weather$DateUTC.br...<-as.character(weather$DateUTC.br...)
    colnames(weather)<-c("TimEDT","TemperatureF","Dew.PointF","Humidity","Sea.Level.PressureIn","VisibilityMPH","Wind.Direction","Wind.SpeedMPH","Gust.SpeedMPH","PrecipitationIn","Events","Conditions","WindDirDegrees","DateUTC")
    weather$DateUTC<-gsub("<br />","",weather$DateUTC)
    weather$DateUTC<-as.POSIXlt(weather$DateUTC)
    weather$DateEST<-weather$DateUTC
    weather$DateEST$hour<-weather$DateEST$hour-4
    
##merge weather with Run data
    df2$index<-sapply(df2$DateTime,Match_Time)
    df2$TemperatureF<-weather[df2$index,2]
    df2$Dew.PointF<-weather[df2$index,3]
    df2$Humidity<-weather[df2$index,4]
    df2$Sea.Level.PressureIn<-weather[df2$index,5]
    df2$VisibilityMPH<-weather[df2$index,6]
    df2$Wind.Direction<-weather[df2$index,7]
    df2$Wind.SpeedMPH<-weather[df2$index,8]
    df2$Gust.SpeedMPH<-weather[df2$index,9]
    df2$PrecipitationIn<-weather[df2$index,10]
    df2$Events<-weather[df2$index,11]
    df2$Conditions<-weather[df2$index,12]
    df2$WindDirDegrees<-weather[df2$index,13]
    