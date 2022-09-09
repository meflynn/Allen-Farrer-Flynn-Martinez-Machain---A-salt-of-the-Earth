# Created by use_targets().
# Follow the comments below to fill in this target script.
# Then follow the manual to check and run the pipeline:
#   https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline # nolint

# Load packages required to define the pipeline:
library(targets)
library(tidyverse)
library(tarchetypes) # Load other packages as needed. # nolint


# Bayes options
# Suppress brms startup messages
suppressPackageStartupMessages(library(brms))

# Set options for brms and stan
options(mc.cores = 4,
        mc.threads = 2,
        brms.backend = "cmdstanr")

set.seed(66502)

# Things that get set in options() are not passed down to workers in future (see
# https://github.com/HenrikBengtsson/future/issues/134), which means all these
# neat options we set here disappear when running tar_make_future() (like
# ordered treatment contrasts and the number of cores used, etc.). The official
# recommendation is to add options() calls to the individual workers.
#
# We do this by including options() in the functions where we define model
# priors and other settings (i.e. pts_settings()). But setting options there
# inside a bunch of files can get tedious, since the number of cores, workers,
# etc. depends on the computer we run this on (i.e. my 4-core personal laptop
# vs. my 16-core work laptop).

# Pass these options to workers using options(worker_options)
worker_options <- options()[c("mc.cores", "mc.threads", "brms.backend")]

# Install custom theme
devtools::install_github("meflynn/flynnprojects")


# Set target options:
tar_option_set(
  packages = c("tidyverse", "data.table", "brms", "sf", "raster", "tidybayes", "geodata", "modelsummary", "rnaturalearth", "flynnprojects", "viridis"), # packages that your targets need to run
  format = "rds" # default storage format
  # Set other options as needed.
)

# tar_make_clustermq() configuration (okay to leave alone):
options(clustermq.scheduler = "multicore")

# tar_make_future() configuration (okay to leave alone):
# Install packages {{future}}, {{future.callr}}, and {{future.batchtools}} to allow use_targets() to configure tar_make_future() options.

# Load the R scripts with your custom functions:
lapply(list.files("R", full.names = TRUE, recursive = TRUE), source)
# source("other_functions.R") # Source other scripts as needed. # nolint

# Name countries we want to include in study
countrylist <- list("DEU", "FRA", "GBR")
countrylist.long <- list("Germany", "France", "United Kingdom")
projcrs <- "EPSG:4326" # Set CRS
wgseqproj <- "EPSG:4087"
gridsize <- 50000
#basesize for plot fonts
# Enable custom fonts
sysfonts::font_add_google("Oswald")
showtext::showtext_auto()
base_size <- 18
base_family <- "Oswald"

# # Replace the target list below with your own:
# # You can use tar_load() to load an object from the pipeline to inspect it manually!
list(

  # Load raw data files
  tar_target(wosis_chem_raw, "data/raw-data/WoSIS_2019_September/wosis_201909_layers_chemical.tsv", format  = "file"),
  tar_target(wosis_phys_raw, "data/raw-data/WoSIS_2019_September/wosis_201909_layers_physical.tsv", format  = "file"),
  tar_target(wosis_profiles_raw, "data/raw-data/WoSIS_2019_September/wosis_201909_profiles.tsv", format  = "file"),

  # Run cleaning functions to generate clean data frames
  tar_target(wosis_chem_clean, clean_wosis(wosis_chem_raw)),
  tar_target(wosis_phys_clean, clean_wosis(wosis_phys_raw)),
  tar_target(wosis_profile_clean, clean_wosis(wosis_profiles_raw)),
  tar_target(bases_clean, clean_bases()), # uses troopdata package so it doesn't need a raw file
  tar_target(wosis_comb_clean, merge_wosis(wosis_profile_clean, wosis_chem_clean, wosis_phys_clean)),
  # Generate maps
  tar_target(baselayer, clean_basemaps(countrylist)),
  tar_target(gridlayer, clean_mapgrid(countrylist)),

  # Merge data together
  tar_target(finaldata, grid_aggregate(gridlayer, bases_clean, wosis_comb_clean)),

  # Plot data
  tar_target(plotslonlat, data_plot_lonlat(wosis_comb_clean, bases_clean, finaldata)),
  tar_target(plotsgrid, data_plot_grid(finaldata))
)


