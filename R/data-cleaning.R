
# Import WOSIS data and clean. Can be applied to several different data sets.
clean_wosis <- function(filename){

  wosis_raw <- data.table::fread(filename) |>
    as.data.frame()

  return(wosis_raw)
}



# Combine the WOSIS files into a single file filtered down by countries
merge_wosis <- function(profile, chemclean, physclean) {

  wosis_merged <- profile |>
    filter(country_name %in% (countrylist.long)) |>
    left_join(chemclean, by = "profile_id") |>
    left_join(physclean, by = "profile_id")

  return(wosis_merged)

}


# Imports base data
clean_bases <- function(filename){

  bases_raw <- troopdata::basedata

  return(bases_raw)

}


# Make maps base layer
clean_basemaps <- function(countrylist) {

  tempmap <- countrylist |>
    map(~ gadm(country = .x, level = 0, path = here::here("data/raw-data"))) |>
    map_dfr(~ st_as_sf(.x))

}

# Make the grids for the maps
clean_mapgrid <- function(countrylist) {

  tempmap <- countrylist |>
    map(~ gadm(country = .x, level = 0, path = here::here("data/raw-data"))) |>
    map_dfr(~ st_as_sf(.x)) |>
    sf::st_transform(wgseqproj)

  tempgrid <- st_make_grid(tempmap, cellsize = c(gridsize, gridsize), square = TRUE, crs = wgseqproj) |> # grid of points
    st_intersection(tempmap) |>
    st_as_sf() |>
    mutate(names = seq(n():1))

}


# Now let's aggregate bases and readings by polygon
grid_aggregate <- function(map, bases, wosis) {

  bases_filtered <- bases |> # Remove missing lat and lon values
  filter(!is.na(lat)) |>
    filter(countryname %in% countrylist.long) |>
    dplyr::select(countryname, lat, lon, basename) |>
    sf::st_as_sf(agr = "basename", coords = c("lon", "lat"), crs = projcrs) |>
    sf::st_set_crs(projcrs) |> # Needs the regular longitude and latitude CRS first
    sf::st_transform(wgseqproj) # Then transform it into the equidistant one.
  # Match the map with the bases data and generate count of bases per grid square
  intersection.bases <- st_intersection(bases_filtered, map) |>
    group_by(names) |>
    dplyr::summarise(basecount = n())

# Make WOSIS data into SF data
  wosis_sf <- wosis |>
    dplyr::select(profile_id, country_id, country_name, latitude, longitude, orgc_value_avg) |>
    sf::st_as_sf(agr = "profile_id", coords = c("longitude", "latitude"), crs = projcrs) |>
    sf::st_set_crs(projcrs) |> # Needs the regular longitude and latitude CRS first
    sf::st_transform(wgseqproj) # Then transform it into the equidistant one.

  # Match map grid with wosis data
  intersection.wosis <- st_intersection(wosis_sf, map) |>
    group_by(names) |>
    dplyr::summarise(orgc_value_avg = mean(orgc_value_avg, na.rm = TRUE))

  # Create the final data set with component data
  finalmap <- map |>
    st_join(intersection.bases) |>
    st_join(intersection.wosis) |>
    distinct()

  return(finalmap)

}


