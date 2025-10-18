# install.packages("ggplot2")
# install.packages("dplyr")
# install.packages("tools")
# install.packages("lubridate")

#' @name finalrun
#' @param lambda[numeric] mean failure rate 
#' @param  num_of_panels [numeric] number of solar panels on the farm
#' @param filename [String] intended name of file 
#' @param L [numeric] latitude of location 
#' @param beta [numeric] tilt angle of the solar panels in degrees
#' @param gamma [numeric] azimuth angle of the solar panels in degrees
#' @param age [numeric] age of the solar panels, assumed all same age
#' @param field_data [data frame] data given by the customer
#' @export
finalrun = function(lambda, num_of_panels, filename, L, beta, gamma, age, field_data){
  
  #all libraries
  #install.packages("dplyr")
  #install.packages("lubridate")
  library(ggplot2)
  library(dplyr)
  library(lubridate)
  library(tools)  # for file path utilities
  
  # source("functions.R")  #linking to file that holds the functions
  
  #Importing in script with all the functions to reference: 
  # source("functions.R")
  
  #calling functions
  #Processing Solar Irradiance Data: 
  results <- solar_flux_from_csv(filename, L, beta, gamma )
  # DEBUGGING
  # print(results)
  
  #Statistical Process Control Chart
  spc_data1 <- solar_spc(read.csv(field_data))
  # DEBUGGING
  # print(spc_data1)
  #Processing Process Control Charts
  
  m = 4; # pre-determined Weibull shape factor value
  b = mttf(lambda, m)
  #Processing Lifetime Graph
  r = lifetime_dist(lambda, num_of_panels, age, m)
  
  print(r)
  return(r)
}

##EXAMPLE RUNS WITH VARIABLE INPUTS 
# results_sample1 = finalrun(0.04, 300, "syracuse_hourly.csv", 43, 30, 0,0,"Sample Data & Generation/sampledata1.csv")
# results_sample2 = finalrun(0.04, 300, "syracuse_hourly.csv", 43, 30, 0,0,"Sample Data & Generation/sampledata2.csv")


