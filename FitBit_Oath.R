library(httr)

# 1. Set up credentials
fitbit_endpoint <- oauth_endpoint(
    request = "https://api.fitbit.com/oauth2/token",
    authorize = "https://www.fitbit.com/oauth2/authorize",
    access = "https://api.fitbit.com/oauth2/token")
myapp <- oauth_app(
    appname = "data_access",
    key = "227NJF", 
    secret = "2d0ef2dddf8a1f755520543d49cd900d")
# 2. Get OAuth token
scope <- c("sleep","activity")  # See dev.fitbit.com/docs/oauth2/#scope
fitbit_token <- oauth2.0_token(fitbit_endpoint, myapp,
                               scope = scope, use_basic_auth = TRUE)

# 3. Make API requests
resp <- GET(url = "https://api.fitbit.com/1/user/-/sleep/date/2016-03-05.json", 
            config(token = fitbit_token))
content(resp)
activities<-GET (url ="https://api.fitbit.com/1/user/-/activities/date/2016-03-05.json", 
                 config(token = fitbit_token))
content(activities)


run<-GET (url="https://api.fitbit.com/1/user/-/activities/1842219540.tcx", 
          config(token = fitbit_token))