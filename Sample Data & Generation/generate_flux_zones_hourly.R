# ---- Dependencies ----
library(dplyr)
library(readr)
library(ggplot2)

generate_and_plot_fluxes <- function(base_filename) {
  # ---- Read the base "ideal" data ----
  base_data <- read_csv(base_filename)
  
  if(!all(c("Day", "Hour", "IncidentFlux") %in% names(base_data))) {
    stop("CSV must have columns: Day, Hour, Irradiance")
  }
  
  # ---- Helper: apply a time-dependent scale factor ----
  apply_scale <- function(data, scale_fn) {
    data %>%
      mutate(IncidentFlux = IncidentFlux * scale_fn(Day)) %>%
      select(Day, Hour, IncidentFlux)
  }
  
  #Data 1 (ideally better)
  set.seed(42)
  good_flux <- base_data %>%
    mutate(IncidentFlux = IncidentFlux * (rnorm(n(), mean = 0.98, sd = 0.05))) %>%
    select(Day, Hour, IncidentFlux)
  
  #Data 2 (should be worse)
  set.seed(99)
  fail_late_flux <- apply_scale(base_data, function(d) {
    # Gradual permanent loss as the year progresses
    ifelse(d < 250, 1.0,
           ifelse(d < 300, 0.8,
                  0.5))
  }) %>%
    # Add noise that increases toward the end of the year
    mutate(
      noise_scale = 0.02 + 0.08 * (Day / 365),  # grows with time
      IncidentFlux = IncidentFlux * (rnorm(n(), mean = 1, sd = noise_scale))
    ) %>%
    select(Day, Hour, IncidentFlux)
  
  # ---- Save to same folder ----
  out_dir <- dirname(normalizePath(base_filename))
  base_name <- tools::file_path_sans_ext(basename(base_filename))
  
  out_good <- file.path(out_dir, paste0(base_name, "_good_family.csv"))
  out_fail_late <- file.path(out_dir, paste0(base_name, "_fail_lateyear.csv"))
  
  write_csv(good_flux, out_good)
  write_csv(fail_late_flux, out_fail_late)
  
  # ---- Combine for Plot ----
  ideal_data <- base_data %>% mutate(Source = "Ideal Model for Syracuse")
  good_data <- good_flux %>% mutate(Source = "Data Set #1")
  late_data <- fail_late_flux %>% mutate(Source = "Data Set #2")
  
  all_data <- bind_rows(ideal_data, good_data, late_data)
  
  # ---- Aggregate by Day ----
  daily_summary <- all_data %>%
    group_by(Day, Source) %>%
    summarize(DailyFlux = mean(IncidentFlux), .groups = "drop")
  
  # ---- Plot ----
  ggplot(daily_summary, aes(x = Day, y = DailyFlux, color = Source)) +
    geom_line(size = 1) +
    scale_color_manual(values = c(
      "Ideal Model for Syracuse" = "darkolivegreen",
      "Data Set #1" = "darkorange3",
      "Data Set #2" = "darkslategray"
    )) +
    labs(
      title = "Syracuse Solar Flux: Ideal vs. Sample Data Arrays",
      x = "Day of Year",
      y = "Average Incident Flux (W/m²)",
      color = "Dataset"
    ) +
    theme_minimal(base_size = 14) +
    theme(
      legend.position = "bottom",
      plot.title = element_text(face = "bold", hjust = 0.5),
      panel.background = element_rect(fill = "beige", color = NA)
    )
}

# Example:
generate_and_plot_fluxes("syracuse_hourly_with_flux.csv")
