

#' @name fsolar
#' @title Failure Function (probability of failure)
#' @param time [numeric] number of years passed
#' @param c [numeric] scale factor of Weibull distribution (1/lambda)
#' @param m [numeric] shape factor of Weibull distribution
#' @export
fsolar = function(time, c, m){ 1 - exp( -1*((time)/c)^m) }


#' @name tsolar
#' @title Time until Failures
#' @param failure_prob [numeric] failure probability
#' @param c [numeric] scale factor of Weibull distribution (1/lambda)
#' @param age [numeric] age of solar panels in years
#' @param m [numeric] shape factor of Weibull distribution
#' @export
tsolar = function(failure_prob, c, age, m) {
  if (age == 0) {
    # Unconditional
    return(( -log(1 - failure_prob) )^(1/m) * c)
  } else {
    # Conditional
    F_age = 1 - exp(- (age / c)^m)
    F_total = failure_prob * (1 - F_age) + F_age
    t_plus_age = ( -log(1 - F_total) )^(1/m) * c
    return(t_plus_age - age)
  }
}


#' @name mttf
#' @title Mean Time to Failure
#' @param lambda [numeric] mean failure rate 
#' @param m [numeric] shape factor of Weibull distribution
#' @export
mttf = function(lambda, m){  
  c = 1/lambda
  result = c * gamma(1 + 1/m)  
  cat("Mean Time to Failure:", round(result, 2), "\n")
  return(result)}


#' @name lifetime_dist
#' @title Graphing Lifetime Distribution
#' @param lambda [numeric] mean failure rate 
#' @param num_of_pannels [numeric] number of solar panels on the farm
#' @param age [numeric] age of solar panels in years
#' @param m [numeric] shape factor of Weibull distribution
#' @note Dependency: `fsolar()` function and `tsolar()` function
#' @export
lifetime_dist = function(lambda, num_of_panels, age, m) {
  # Create a data frame with t and fsolar
  t_vals = seq(0, 100, by = 0.1)
  c = 1/lambda
  
  # If age > 0, use conditional failure function
  if (age > 0) {
    F_age = fsolar(age, c, m)
    F_total = fsolar(t_vals + age, c, m)
    f_cond = (F_total - F_age) / (1 - F_age)  # conditional probability
    df = data.frame(t = t_vals, f_t = f_cond *num_of_panels)
    title = paste("Conditional Failures Over Time (Given Survival to", age, "yrs)")
  } else {
    df = data.frame(t = t_vals, f_t = fsolar(t_vals, c, m)*num_of_panels)
    title = "Expected Failures Over Time"
  }
  
  # Plot using ggplot
  gg <- ggplot(df, aes(x = t, y = f_t)) +
    geom_line(color = "blue", size = 1.2) +
    labs(title = title,
         x = ifelse(age > 0, "Years After Age", "Time (Years)"),
         y = "Expected Number of Failed Panels") +
    theme_minimal(base_size = 14)
  print(gg)
  
  #time 1% of solar panels are expected to fail
  time0.01 = tsolar(0.01, c, age, m)
  cat("After", round(time0.01, 1), "years, 1% of the solar panels on the farm are expected to have failed.\n")
  
  #time 5% of solar panels are expected to fail
  time0.05 = tsolar(0.05, c, age, m)
  cat("After", round(time0.05, 1), "years, 5% of the solar panels on the farm are expected to have failed.\n")
  
}


#' @name solar_flux_from_csv
#' @title Calculating Solar Flux from csv 
#' @param filename [String] intended name of file 
#' @param L [numeric] latitude of location 
#' @param beta [numeric] tilt angle of the solar panels in degrees
#' @param gamma [numeric] azimuth angle of the solar panels in degrees
#' @export
solar_flux_from_csv <- function(filename, L, beta, gamma) {
  # ---- Dependencies ----
  library(dplyr)
  library(ggplot2)
  library(lubridate)
  library(tools)  # for file path utilities
  
  # ---- Read Data ----
  data <- read.csv(filename)
  if(!all(c("Day", "Hour", "Irradiance") %in% names(data))) {
    stop("CSV must have columns: Day, Hour, Irradiance")
  }
  
  # ---- Define Month for Each Day ----
  days_in_month <- c(31,28,31,30,31,30,31,31,30,31,30,31)
  month_edges <- c(0, cumsum(days_in_month))
  
  data$Month <- sapply(data$Day, function(N) {
    which(N > month_edges & N <= c(month_edges[-1], 366))[1]
  })
  
  # ---- Compute Incident Flux ----
  data <- data %>%
    rowwise() %>%
    mutate(
      omega = (Hour - 12) * 15,  # Hour angle (deg)
      delta = 23.45 * sin(pi/180 * (360 * (284 + Day) / 365)),  # Declination (deg)
      alpha_s = asin(sin(delta*pi/180)*sin(L*pi/180) + 
                       cos(delta*pi/180)*cos(L*pi/180)*cos(omega*pi/180)) * 180/pi,
      gamma_s = asin(cos(delta*pi/180)*sin(omega*pi/180) / cos(alpha_s*pi/180)) * 180/pi,
      theta_i = acos(sin(alpha_s*pi/180)*cos(beta*pi/180) + 
                       cos(alpha_s*pi/180)*sin(beta*pi/180)*cos((gamma - gamma_s)*pi/180)) * 180/pi,
      IncidentFlux = pmax(0, Irradiance * cos(theta_i*pi/180))
    ) %>%
    ungroup()
  
  # ---- Monthly Hourly Averages ----
  monthly_avg <- data %>%
    group_by(Month, Hour) %>%
    summarize(mean_Irradiance = mean(Irradiance),
              mean_IncidentFlux = mean(IncidentFlux),
              .groups = "drop")
  
  # ---- Plot ----
  # ---- Plot ----
  month_names <- month.name
  
  season_gradient <- c(
    "January" = "#2b83ba",   
    "February" = "#74add1",
    "March" = "#abd9e9",
    "April" = "#d9ef8b",
    "May" = "#ffffbf",
    "June" = "#fee08b",
    "July" = "#fdae61",
    "August" = "#f46d43",
    "September" = "#d73027",
    "October" = "#a50026",
    "November" = "#313695",
    "December" = "#4575b4"
  )
  
  p <- ggplot(monthly_avg, aes(
    x = Hour,
    y = mean_IncidentFlux,
    color = factor(Month, labels = month_names)
  )) +
    geom_line(size = 1.1) +
    scale_color_manual(values = season_gradient, name = "Month") +
    labs(
      title = "Syracuse Monthly Average Solar Flux Through the Year",
      x = "Hour of Day",
      y = "Incident Solar Flux (W/m²)"
    ) +
    theme_minimal(base_size = 13) +
    theme(
      legend.position = "right",
      plot.title = element_text(face = "bold", hjust = 0.5)
    )
  
  print(p)
  
  # ---- Save output CSVs ----
  out_dir <- dirname(normalizePath(filename))
  base_name <- file_path_sans_ext(basename(filename))
  
  #Full hourly data
  out_hourly <- file.path(out_dir, paste0(base_name, "_with_flux.csv"))
  write.csv(data, out_hourly, row.names = FALSE)
  
  #Monthly averages
  out_monthly <- file.path(out_dir, paste0(base_name, "_monthly_avg.csv"))
  write.csv(monthly_avg, out_monthly, row.names = FALSE)
  
  message("✅ Saved full hourly flux data: ", out_hourly)
  message("✅ Saved monthly averages: ", out_monthly)
  
  return(list(hourly = data, monthly = monthly_avg))
}


#' @name solar_spc
#' @title Solar Statistical Process Control 
#' @param data [data frame] file of solar flux over time for the solar farm 
#' @export
solar_spc <- function(data){
  #Dependencies
  library(ggplot2)
  library(dplyr)
  
  #Run theme for clean graphs
  theme_set(
    # we tell ggplot to give EVERY plot this theme
    theme_classic(base_size = 14) +
      # With these theme traits, including
      theme(
        # Putting the legend on the bottom, if applicable
        legend.position = "bottom",
        # horizontally justify plot subtitle and caption in center
        plot.title = element_text(hjust = 0.5),
        plot.subtitle = element_text(hjust = 0.5),
        plot.caption = element_text(hjust = 0.5),
        # Getting rid of busy axis ticks
        axis.ticks = element_blank(),
        # Getting rid of busy axis lines
        axis.line = element_blank(),
        # Surrounding the plot in a nice grey border
        panel.border = element_rect(fill = NA, color = "darkslategray"),
        # Remove the right margin, for easy joining of plots
        plot.margin = margin(r = 0)
      )
  )
  #filter out when incident flux is 0 (nighttime)
  data_filtered <- data %>%
    filter(data$IncidentFlux != 0)
  n = nrow(data_filtered)
  #pull only aspects needed
  #days, total incident flux, and flux from each zone
  flux <- data.frame(
    time = array(1:n),
    days = data_filtered$Day,
    incident_flux = data_filtered$IncidentFlux,
    zone_1 = data_filtered$ZoneFluxes_Zone1,
    zone_2 = data_filtered$ZoneFluxes_Zone2,
    zone_3 = data_filtered$ZoneFluxes_Zone3,
    zone_4 = data_filtered$ZoneFluxes_Zone4,
    zone_5 = data_filtered$ZoneFluxes_Zone5
  )
  #turn it into a tidy data.frame we can compute statistics of quickly
  flux_zones = flux %>% group_by(days) %>%
    summarize(zone = c(zone_1, zone_2, zone_3, zone_4, zone_5)) %>%
    ungroup()
  #compute short statistics per day
  stat_s = flux_zones %>%
    group_by(days) %>%
    summarize(
      sd_s = sd(zone), #standard deviation for each day
      mean_s = mean(zone), #mean of each day
      n_w = n(), #number in each day
    )
  
  #moving average function (needed as solar flux varies throughout the year)
  moving_average <- function(x, n = 20) {
    weights <- 1:n                    # linear weights (1, 2, 3, ..., n)
    stats::filter(x, weights / sum(weights), sides = 1)
  }
  
  sigma_s = sqrt(moving_average((stat_s$sd_s)^2)) #calculate sigma short
  mean_t = moving_average(stat_s$mean_s) #calculate total mean
  sd_t = moving_average(stat_s$sd_s) #total standard deviation
  LCL = mean_t - (3*sigma_s/sqrt(stat_s$n_w)) #Lower control limit calc
  
  #moving time average of total statistics
  stat_t = stat_s %>%
    mutate(
      sigma_s , #calculate sigma short
      mean_t, #calculate total mean
      sd_t, #standard deviation
      LCL # lower control limit
    )
  
  #create plot
  spc_plot = ggplot(data = stat_t, aes(x = days)) +
    # LCL line (orange)
    geom_line(aes(y = LCL, color = "LCL")) +
    # Mean points
    geom_point(aes(y = mean_s), size = 0.5, color = "black") +
    # Total mean line (pink)
    geom_line(aes(y = mean_t, color = "Total Mean")) +
    # Legend settings
    scale_color_manual(
      name = "Legend",
      values = c("Total Mean" = "pink", "LCL" = "orange")
    ) +
    labs(
      x = "Days",
      y = "Mean Value",
      title = "Solar Panel Flux Control Chart"
    ) +
    theme_classic(base_size = 14) +
    theme(legend.position = "bottom")
  
  print(spc_plot)
  
  detect_below_LCL <- function(data, mean_col, LCL_col, day_col = "days") {
    # --- Extract relevant columns ---
    mean_s <- data[[mean_col]]   # daily mean value
    LCL    <- data[[LCL_col]]    # lower control limit
    days   <- data[[day_col]]    # time in days
    # --- Identify points after system stabilization period (e.g., 100 days)
    # This avoids flagging early startup variation
    valid_idx <- which(days > 100 & mean_s < LCL)
    # --- If any days are flagged below LCL ---
    if (length(valid_idx) > 0) {
      flagged_days <- days[valid_idx]
      # Format message with all flagged day numbers
      message_text <- paste("Maintenance Flagged at days:",
                            paste(flagged_days, collapse = ", "))
      cat(message_text, "\n")
    } else {
      # If no violations, return a quiet confirmation
      cat("No maintenance needed.\n")
    }
  }
  detect_below_LCL <- function(data, mean_col, LCL_col, day_col = "days") {
    # --- Extract relevant columns ---
    mean_s <- data[[mean_col]]   # daily mean value
    LCL    <- data[[LCL_col]]    # lower control limit
    days   <- data[[day_col]]    # time in days
    # --- Identify points after system stabilization period (e.g., first 100 days)
    # Avoids flagging natural variation early in operation
    valid_idx <- which(days > 100 & mean_s < LCL)
    # --- Check if any points fall below LCL ---
    if (length(valid_idx) > 0) {
      first_flag_day <- days[min(valid_idx)]  # earliest flagged day
      cat("Maintenance flagged starting at day:", first_flag_day, "\n")
    } else {
      cat("No maintenance needed.\n")
    }
  }
  detect_below_LCL(stat_t, "mean_s", "LCL")
}


