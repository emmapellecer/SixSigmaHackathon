# ---- Dependencies ----
library(dplyr)
library(readr)
library(ggplot2)
library(tools)

generate_and_plot_fluxes <- function(base_filename) {
  # ---- Read the base "ideal" data ----
  base_data <- read_csv(base_filename)
  
  # Keep Irradiance Constant Columns for Consistency
  if(!all(c("Day", "Hour", "Irradiance", "Month", "omega", "delta",
            "alpha_s", "gamma_s", "theta_i", "IncidentFlux") %in% names(base_data))) {
    stop("CSV must include columns: Day, Hour, Irradiance, Month, omega, delta, alpha_s, gamma_s, theta_i, IncidentFlux")
  }
  
  
  set.seed(99)
  fail_late_flux <- base_data %>%
    mutate(
      
      degradation = ifelse(Day < 250, 1.0,
                           ifelse(Day < 300, 0.6, 0.15)),
      #Simulate some level of noise and degradation
      noise_scale = 0.05 + 0.15 * (Day / 365),
      IncidentFlux = IncidentFlux * degradation *
        rnorm(n(), mean = 1, sd = noise_scale)
    )
  
  #Split into subgroups to represent different zones of the solar panels
  set.seed(101)
  n <- nrow(fail_late_flux)
  zones <- lapply(1:5, function(z) {
    base_offset <- c(1.02, 0.98, 1.00, 0.9, 0.8)[z]
    base_noise <- c(0.03, 0.04, 0.03, 0.07, 0.1)[z]
    
    # Aggressive degradation curves
    degrade_scale <- ifelse(z < 4, 1,
                            ifelse(z == 4,
                                   ifelse(fail_late_flux$Day < 250, 1,
                                          0.75 - 0.55 * ((fail_late_flux$Day - 250) / 115)), # → 0.2
                                   ifelse(fail_late_flux$Day < 250, 1,
                                          0.65 - 0.65 * ((fail_late_flux$Day - 250) / 115)))) # → ~0.0
    #Force shutdown/degradation
    flicker <- 1 + rnorm(n, mean = 0, sd = base_noise * (fail_late_flux$Day / 365) * 3)
    flux <- fail_late_flux$IncidentFlux * base_offset * degrade_scale * flicker
    flux[flux < 0] <- 0  # no negative flux
    return(flux)
  })
  
  #Match to ideal solar flux output
  fail_late_zones <- fail_late_flux %>%
    mutate(
      ZoneFluxes_Zone1 = zones[[1]],
      ZoneFluxes_Zone2 = zones[[2]],
      ZoneFluxes_Zone3 = zones[[3]],
      ZoneFluxes_Zone4 = zones[[4]],
      ZoneFluxes_Zone5 = zones[[5]]
    ) %>%
    select(Day, Hour, Irradiance, Month, omega, delta,
           alpha_s, gamma_s, theta_i, IncidentFlux,
           ZoneFluxes_Zone1, ZoneFluxes_Zone2, ZoneFluxes_Zone3,
           ZoneFluxes_Zone4, ZoneFluxes_Zone5)
  
  # ---- Save ----
  out_dir <- dirname(normalizePath(base_filename))
  base_name <- file_path_sans_ext(basename(base_filename))
  out_fail_late <- file.path(out_dir, paste0(base_name, "_fail_lateyear_zones_hourly.csv"))
  write_csv(fail_late_zones, out_fail_late, na = "")
  
}

# Example:
generate_and_plot_fluxes("syracuse_hourly_with_flux.csv")
