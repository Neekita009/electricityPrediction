library(mongolite)
library(xts)
library(ggplot2)
library(lubridate)
library(forecast)
library(dplyr)
library(openxlsx)
library(tseries)

#write.xlsx(homeDataA, "C:/Users/neeki/Desktop/assignment3/homeDataA.xlsx")
#write.xlsx(homeDataB, "C:/Users/neeki/Desktop/assignment3/homeDataB.xlsx")
#write.xlsx(homeDataC, "C:/Users/neeki/Desktop/assignment3/homeDataC.xlsx")
#write.xlsx(homeDataD, "C:/Users/neeki/Desktop/assignment3/homeDataD.xlsx")
#write.xlsx(homeDataF, "C:/Users/neeki/Desktop/assignment3/homeDataF.xlsx")
#write.xlsx(homeDataG, "C:/Users/neeki/Desktop/assignment3/homeDataG.xlsx")

#write.xlsx(CompairGrid, "C:/Users/neeki/Desktop/assignment3/BothData.xlsx")
#write.xlsx(GridVsHouses_DF, "C:/Users/neeki/Desktop/assignment3/dataGridWOptimized.xlsx")
#write.xlsx(GridVshouses, "C:/Users/neeki/Desktop/assignment3/dataGridNWOptimized.xlsx")

homeA <- mongo(collection = "HomeA",db="admin",url = "mongodb://localhost")
homeDataA <- homeA$find('{}')
homeB <- mongo(collection = "HomeB",db="admin",url = "mongodb://localhost")
homeDataB <- homeB$find('{}')
homeC <- mongo(collection = "HomeC",db="admin",url = "mongodb://localhost")
homeDataC <- homeC$find('{}')
homeD <- mongo(collection = "HomeD",db="admin",url = "mongodb://localhost")
homeDataD <- homeD$find('{}')
homeF <- mongo(collection = "HomeF",db="admin",url = "mongodb://localhost")
homeDataF <- homeF$find('{}')
homeG <- mongo(collection = "HomeG",db="admin",url = "mongodb://localhost")
homeDataG <- homeG$find('{}')

#Data cleaning using function dataCleaning
DataA<- dataCleaning(homeDataA, "A")
HourlyA <- DataA$Data # storing hourly data of house A
cleanDataA <- DataA$SumOfData # mean of the power consumed by house A on hourly basis 
DataB <- dataCleaning(homeDataB , "B")
HourlyB <- DataB$Data
cleanDataB <- DataB$SumOfData
DataC<- dataCleaning(homeDataC, "C")
HourlyC <- DataC$Data
cleanDataC <- DataC$SumOfData
DataD<- dataCleaning(homeDataD, "D")
HourlyD <- DataD$Data
cleanDataD <- DataD$SumOfData
DataF<- dataCleaning(homeDataF, "F")
HourlyF <- DataF$Data
cleanDataF <- DataF$SumOfData
DataG<- dataCleaning(homeDataG, "G")
HourlyG <- DataG$Data
cleanDataG <- DataG$SumOfData

# formation of grid 

GridDataIndi <- cbind(cleanDataA,cleanDataB,cleanDataC,cleanDataF,cleanDataG)
GridDataIndi[is.na(GridDataIndi)] <- 0
gridData <- period.apply(GridDataIndi, INDEX=endpoints(GridDataIndi, "hours"), FUN=sum)
names(gridData) <- "GridData"
gridData <- tbl_df(gridData)

#selecting the background appliances 
# Data sub-setting

HourlyD <- selectBackgroudApp(tbl_df(HourlyD))
HourlyA <- selectBackgroudApp(tbl_df(HourlyA))
HourlyB <- selectBackgroudApp(tbl_df(HourlyB))
HourlyC <- selectBackgroudApp(tbl_df(HourlyC))
HourlyF <- selectBackgroudApp(tbl_df(HourlyF))
HourlyG <- selectBackgroudApp(tbl_df(HourlyG))


# electric grid vs the houses 
l <- list(HourlyA,HourlyB,HourlyC,HourlyD,HourlyF,HourlyG,gridData)
GridVshouses <- l[[1]]
for(i in 2:length(l)){
  GridVshouses<- transform(merge(GridVshouses,l[[i]],by=0,all=TRUE), row.names=Row.names, Row.names=NULL)
}

#converting zoo object to dataframe 
GridVsHouses_DF <- cbind(DateTime = row.names(GridVshouses),GridVshouses)


#optimization
a=1
GridData <- which(colnames(GridVsHouses_DF)=="GridData")
for(z in seq(from=24, to=8782 , by=24))
{
  
  for(k in a:z)
  {
    
    maxValue <- GridVsHouses_DF[a:z,] %>% top_n(1)
    
    if(maxValue$GridData > 4)
    {
      
      minValue <-  GridVsHouses_DF[a:z,] %>% top_n(-3)
      MaxdataNWGrid <- select(maxValue,-starts_with("GridData"),-starts_with("DateTime")) 
      selectMaxAppliance <- sort(MaxdataNWGrid[,-1],decreasing = TRUE)[1:3]
      
      
      for(i in 1:3)
      {
        ColID=which(colnames(GridVsHouses_DF)==names(selectMaxAppliance[i]))
        MaxrowID=which(rownames(GridVsHouses_DF)== maxValue$DateTime)
        MinrowID= which(rownames(GridVsHouses_DF)== minValue[i,]$DateTime)
        
        if(GridVsHouses_DF[MaxrowID,GridData] < 2)
        {
          break;
        }
        else
        {
         
          GridVsHouses_DF[MaxrowID,GridData] <- GridVsHouses_DF[MaxrowID,GridData] - GridVsHouses_DF[MaxrowID,ColID]
          GridVsHouses_DF[MinrowID,GridData] <- GridVsHouses_DF[MinrowID,GridData]  + GridVsHouses_DF[MaxrowID,ColID]
          temp <- GridVsHouses_DF[MaxrowID,ColID]
          GridVsHouses_DF[MaxrowID,ColID] <- GridVsHouses_DF[MinrowID,ColID]
          GridVsHouses_DF[MinrowID,ColID] <- temp
          
        }
      }
    }
    
  }
  a=k
  
}


CompairGrid <- GridDataIndi
CompairGrid$GridWithOutOptimizing <- GridVshouses$GridData
CompairGrid$GridOptimized <- GridVsHouses_DF$GridData
CompairGrid<-CompairGrid[,-1:-5]
CompairGrid[CompairGrid < 0] <- 1
#comparing optimed and not optimised grid data 
autoplot(CompairGrid, facets = NULL)


#Forecasting 
CompairGrid <- tbl_df(CompairGrid)
CompairGrid <- cbind(DateTime = row.names(CompairGrid),CompairGrid)
rownames(CompairGrid) <- 1:nrow(CompairGrid)
CompairGrid$DateTime <- as.Date(CompairGrid$DateTime )

#pridiction for grid data before optimization

#the data of grid before optimization 
ggplot(CompairGrid, aes(DateTime, GridWithOutOptimizing)) + geom_line() + scale_x_date('month')  + ylab("GH") +
  xlab("") 
#converting gridDatabeforeoptimization into timeseries
timeclean_BO = ts(CompairGrid[, c("GridWithOutOptimizing")])
# cleaning the data and removing outliers 
CompairGrid$clean_BO = tsclean(timeclean_BO) 
#ploting the cleaned data 
ggplot() +
  geom_line(data = CompairGrid, aes(x = DateTime, y = clean_BO)) + ylab('GH')
#performing moving aggregation to smooth the series
CompairGrid$weekly_BO = ma(CompairGrid$clean_BO, order=168) # hourly data 7*24
CompairGrid$monthly_BO = ma(CompairGrid$clean_BO, order=672)# monthly data 168*4

#compairing the weekly and monthly smoothing with the original data 
ggplot() +
  geom_line(data = CompairGrid, aes(x = DateTime, y = clean_BO, colour = "Counts")) +
  geom_line(data = CompairGrid, aes(x = DateTime, y = weekly_BO,   colour = "Weekly Moving Average"))  +
  geom_line(data = CompairGrid, aes(x = DateTime, y = monthly_BO, colour = "Monthly Moving Average"))  +
  #geom_line(data = CompairGrid, aes(x = DateTime, y = yearly_BO, colour = "year Moving Average"))  +
  ylab('GH')

cnt_BO = ts(na.omit(CompairGrid$weekly_BO), frequency=720)
#calculating seasonality from the series 
#stl(cnt_BO, s.window="periodic")
decomp_BO = decompose(cnt_BO, "multiplicative")
plot(decomp_BO)
#removing the seasonal components  
deseasonal_BO <- cnt_BO/decomp_BO$seasonal

#finding the difference 
deseasonal_BO_d2 = diff(cnt_BO, differences = 2)
plot(deseasonal_BO_d2)

#Auto Fitting the series 
fit<-auto.arima(deseasonal_BO, seasonal = FALSE)
tsdisplay(residuals(fit), lag.max=45, main='Model Residuals')

fit2 = arima(deseasonal_BO, order=c(1,2,2))
tsdisplay(residuals(fit2), lag.max=45, main='Model Residuals')
#pridiction
BeforeOptimized<- arima(deseasonal_BO[-c(8000:8782)],order = c(1,2,2)) %>% forecast(h=782) 
autoplot(BeforeOptimized,main="Before Optimization")
plot(BeforeOptimized,main="Before Optimization")
lines(ts(deseasonal_BO))
# pridiction with seasonal componenet 
BeforeOptimized_SA<- auto.arima(deseasonal_BO[-c(8000:8782)], seasonal = TRUE) %>% forecast(h=782) 
autoplot(BeforeOptimized_SA,main="Before Optimization with Seasonality")
plot(BeforeOptimized_SA,main="Before Optimization")
lines(ts(deseasonal_BO))

#pridiction of grid Aftre optimization 
ggplot(CompairGrid, aes(DateTime, GridOptimized)) + geom_line() + scale_x_date('month')  + ylab("GH") +
  xlab("") 
#converting gridDatabeforeoptimization into timeseries
timeclean_AO = ts(CompairGrid[, c("GridOptimized")])
# cleaning the data and removing outliers 
CompairGrid$clean_AO = tsclean(timeclean_AO) 
#ploting the cleaned data 
ggplot() +
  geom_line(data = CompairGrid, aes(x = DateTime, y = clean_AO)) + ylab('GH')
#performing moving aggregation to smooth the series
CompairGrid$weekly_AO = ma(CompairGrid$clean_AO, order=168,centre = T)
CompairGrid$monthly_AO = ma(CompairGrid$clean_AO, order=672,centre = T)

#compairing the weekly and monthly smoothing with the original data 
ggplot() +
  geom_line(data = CompairGrid, aes(x = DateTime, y = clean_AO, colour = "Counts")) +
  geom_line(data = CompairGrid, aes(x = DateTime, y = weekly_AO,   colour = "Weekly Moving Average"))  +
  geom_line(data = CompairGrid, aes(x = DateTime, y = monthly_AO, colour = "Monthly Moving Average"))  +
  #geom_line(data = CompairGrid, aes(x = DateTime, y = yearly_AO, colour = "year Moving Average"))  +
  ylab('GH')

cnt_AO = ts(na.omit(CompairGrid$weekly_AO), frequency=720)
#calculating seasonality from the series additive

decomp_AO = decompose(cnt_AO, "multiplicative")
plot(decomp_AO)
#removing the seasonal components  
deseasonal_AO <- cnt_AO/decomp_AO$seasonal

#finding the difference 
deseasonal_AO_d1 = diff(cnt_AO, differences = 1)

#Auto Fitting the series 
fit3<-auto.arima(deseasonal_AO, seasonal = FALSE)
tsdisplay(residuals(fit3), lag.max=45)
fit4<-arima(deseasonal_AO, order=c(1,2,2))
tsdisplay(residuals(fit4), lag.max=45)
#pridiction 
AfterOptimized<- arima(deseasonal_AO[-c(8000:8782)], order=c(1,2,2)) %>% forecast(h=782) 
autoplot(AfterOptimized, main="After optimization")
plot(AfterOptimized,main="After optimization")
lines(ts(deseasonal_AO_AD))

#prediction with seasonal components 
AfterOptimized_SA<- auto.arima(deseasonal_AO[-c(8000:8782)], seasonal = TRUE) %>% forecast(h=782) 
autoplot(AfterOptimized_SA, main="After optimization with Seasonality")
plot(AfterOptimized_SA,main="After optimization with Seasonality")
lines(ts(deseasonal_AO))


# functions for cleaning and sorting data 
# separating the background appliance 
selectBackgroudApp <- function(data){
  newData <-  select(data, contains("Furnace"),contains("CellarOutlets"),
                     contains("WashingMachine"),contains("Heater"),
                     contains("WaterHeater"),contains("Fridge"), contains("Dishwasher"), 
                     contains("TubWhirpool"), contains("pool"),contains("Winecellar"),
                     contains("Well"),contains("Barn"), contains("Pump"),
                     contains("FreshAirVentilation"),contains("Dryer"),
                     contains("Basement"),contains("Garage"),contains("Refrigerator")) 
  return(newData)
}



#cleaning the data
dataCleaning <- function(data,n){
  #cleaning the names of the columns 
  names(data) = gsub("&|\\[|\\]|[[:space:]]","",names(data))
  #converting date format 
  data$DateTime<-as.POSIXct(strptime(data$DateTime,format="%Y-%m-%d %H"))
  #calculating mean of all the power consumed by appliance in each house 
  aggData<-aggregate(data[,-1:-3],by=list(data$DateTime),mean)
  x <- xts(aggData[,-1], as.POSIXct(aggData[,1]))
  #manupulating name of the header 
  colnames(x) = paste(n, colnames(x), sep = "_")
  SumOfData <- period.apply(x, INDEX=endpoints(x, "hours"), FUN=sum)
  ListAll <- list("SumOfData"= SumOfData,"Data"= x)
  return(ListAll)
}


