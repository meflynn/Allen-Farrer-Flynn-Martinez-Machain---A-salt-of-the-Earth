# Now let's plot some data!
data_plot_lonlat <- function(wosis, bases, griddata) {

  #plot some of the wosis data raw longitude and latitude values
  #
  #Let's set up a basemap
  tempmap <- countrylist |>
    map(~ gadm(country = .x, level = 0, path = here::here("data/raw-data"))) |>
    map_dfr(~ st_as_sf(.x))

  # Base Map

    bases_temp <- bases |>
      filter(countryname %in% countrylist.long)

    ggplot2::ggplot() +
    geom_sf(data = tempmap, size = 0.1, color = "black", fill = "antiquewhite") +
    geom_point(data = bases_temp, aes(x = lon, y = lat), alpha = 0.3, color = "purple") +
    theme_flynn_map(base_size = base_size, base_family = base_family) +
    labs(title = "US Military Base Locations",
         x = "",
         y = "")

  ggsave(here::here("figures/plot-bases-lonlat.png"), height = 5, width = 8, units = "in", device = NULL)


  # Organic Carbon
  wosis_temp <- wosis |>
    filter(!is.na(orgc_value_avg))

  ggplot2::ggplot() +
    geom_sf(data = tempmap, size = 0.1, color = "black", fill = "antiquewhite") +
    geom_point(data = wosis_temp, aes(x = longitude, y = latitude), alpha = 0.3, color = "purple") +
    theme_flynn_map(base_size = base_size, base_family = base_family) +
    labs(title = "Organic Carbon Sampling Sites",
         x = "",
         y = "")

  ggsave(here::here("figures/plot-organic-carbon.png"), height = 5, width = 8, units = "in", device = NULL)

}



# Function for grid-based plots

data_plot_grid <- function(data){

  # Base Plots
  tempdata <- data

  ggplot() +
    geom_sf(data = tempdata, aes(fill = basecount), color = "black", size = 0.1) +
    theme_flynn_map(base_size = base_size, base_family = base_family) +
    viridis::scale_fill_viridis(na.value = "gray90") +
    labs(title = "Count of US Military Bases Per Grid Cell",
         fill = "Base Count",
         x = "",
         y = "")

  ggsave(here::here("figures/plot-bases-grid.png"), height = 5, width = 8, units = "in", device = NULL)


  # Organic Carbon
  ggplot() +
  geom_sf(data = tempdata, aes(fill = orgc_value_avg), color = "black", size = 0.1) +
    theme_flynn_map(base_size = base_size, base_family = base_family) +
    viridis::scale_fill_viridis(na.value = "gray90") +
    labs(title = "Average Organic Carbon Measurement Per Grid Cell",
         fill = "Organic Carbon",
         x = "",
         y = "")

  ggsave(here::here("figures/plot-organic-carbon-grid.png"), height = 5, width = 8, units = "in", device = NULL)
}
