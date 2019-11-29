<# 

This script returns the current date time from http://worldclockapi.com/ using REST API service.

You can find the latest uri from the site above.

Eastern Standard Time http://worldclockapi.com/api/json/est/now

Coordinated Universal Time http://worldclockapi.com/api/json/utc/now

Also supports JSONP
Central European Standard Time http://worldclockapi.com/api/jsonp/cet/now?callback=mycallback

#>

# utc time url
[string] $WorldClockAPIUrl = 'http://worldclockapi.com/api/json/utc/now'

# Invoke Get method. The API returns the output in json format, but by default Invoke-RestMethod will convert from JSON to readable format (pacustomobject)
[psobject] $ApiResult = Invoke-RestMethod -Method Get -Uri $WorldClockAPIUrl 

<# Selecting only current datetime from the api output
$id                   : 1
currentDateTime       : 2019-08-27T11:51Z
utcOffset             : 00:00:00
isDayLightSavingsTime : False
dayOfTheWeek          : Tuesday
timeZoneName          : UTC
currentFileTime       : 132113802749969955
ordinalDate           : 2019-239
serviceResponse       :
#>
[string] $UTCTimeString = $ApiResult.currentDateTime

# Convert the string to datetime using .Net datetime class method Parse(), and returns datetime in default culture
[datetime]$DateTime =  [System.DateTime]::Parse($UTCTimeString)

# output datetime
return $DateTime
