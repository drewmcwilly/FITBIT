Match_Time<-function(x){
    y<-which.min(abs(difftime (x,weather$DateEST, units="mins")))
                
    y
}