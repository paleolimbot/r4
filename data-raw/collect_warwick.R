
library(tidyverse)
library(sf)

unzip("data-raw/dp505v1sgx_Warwick_Mtn_Litho_Geochem.zip", exdir = "data-raw")

sample_locs <- read_sf(
  "data-raw/d505wi_Warwick_Mtn_Litho_Geochem/shp/d505wicl_sample_locations/d505wicl_sample_locations.shp"
) %>%
  st_set_geometry(NULL)

litho <- read_sf(
  "data-raw/d505wi_Warwick_Mtn_Litho_Geochem/shp/d505wiml_litho_descriptions/d505wiml_litho_descriptions.shp"
) %>%
  st_set_geometry(NULL)

pxrf <- read_sf(
  "data-raw/d505wi_Warwick_Mtn_Litho_Geochem/shp/d505wipx_pXRF_analyses/d505wipx_pXRF_analyses.shp"
) %>%
  st_set_geometry(NULL)


sample_locs_sub <- sample_locs %>%
  select(station_id = stati_num, longitude = LON_dd, latitude = LAT_dd, date_sampled = date, geologist)

litho_sub <- litho %>%
  select(
    station_id = stati_num, sample_id = Sample_No, 
    type = type_mat, quality = smpl_qlty, rock_type = type_rock,
    rock_name = name_rock, rock_group = geol_grp, rock_age = age,
    magnetics, legend = av_legend, rock_gcode = gcode_desc
  )

pxrf_sub <- pxrf %>%
  select(sample_id = Sample_No, S_ppm:U_ppm)

warwick_raw <- sample_locs_sub %>%
  left_join(litho_sub, by = "station_id") %>%
  left_join(pxrf_sub, by = "sample_id")

warwick <- warwick_raw %>%
  mutate(
    date_sampled = suppressWarnings(lubridate::mdy(date_sampled)),
    rock_desc = rock_name,
    # last word of rock desc
    rock_name = rock_desc %>%
      str_remove("\\s*high Zr") %>%
      str_remove("\\s*mafic inclusions") %>%
      str_remove("\\s*spatter") %>%
      str_remove("\\s*spherulitic") %>%
      str_extract("(\\s+[^ ]+$)|(^[^ ]+$)") %>% str_trim(),
    type = na_if(type, "No Sample"),
    quality = na_if(quality, "No Sample"),
    sample_id = na_if(sample_id, "No Sample"),
    magnetics = na_if(magnetics, "none") %>% as.numeric()
  ) %>%
  filter(!is.na(rock_gcode) | !is.na(S_ppm)) %>%
  select(
    station_id, starts_with("sample"), longitude, latitude, 
    type, starts_with("rock"), legend, everything()
  ) %>%
  write_csv("data/warwick.csv")

writexl::write_xlsx(warwick, "data/warwick.xlsx")

unlink("data-raw/d505wi_Warwick_Mtn_Litho_Geochem/", recursive = TRUE)
