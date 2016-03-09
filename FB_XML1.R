    require(XML)
    library(plyr)
    library(dplyr)
    library(stringr)
    xml_file<-"1842219540.tcx"
    
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

#append extra columns
    df2<-mutate(df2, Meters_Interval=Meters_Distance- lag(Meters_Distance, default=0))
    df2<-mutate(df2, Miles=floor(1+(Meters_Distance/1609.344)))
    df2<-mutate(df2,DateTime=as.POSIXct(Time))
    df2<-mutate(df2,Elapsed_Time=(DateTime-DateTime[1])/60)
                                     
    