library(raster)
library(tidyverse)

### make base raster of CA bight
gl_rast <- raster(ext = extent(c(xmin = -180, xmax = +180, ymin = -90, ymax = +90)),
                  res = 0.5, crs = '+init=epsg:4326')
values(gl_rast) <- 1:ncell(gl_rast)

ca_ext <- extent(c(xmin = -125, xmax = -115, ymin = 32, ymax = 38))

ca_rast <- gl_rast %>%
  crop(ca_ext)

ca_rast

### read files
am_d <- '/home/shares/ohi/git-annex/globalprep/_raw_data/aquamaps/d2018'
am_spp_cells <- data.table::fread(file.path(am_d, 'hcaf_species_native_ver0816c_fixed.csv'))
am_spp <- data.table::fread(file.path(am_d, 'speciesoccursum_ver0816c.csv')) %>%
  janitor::clean_names() %>%
  rename(am_sid = speciesid)

ca_cells <- am_spp_cells %>%
  filter(loiczid %in% values(ca_rast))
ca_spp <- am_spp %>%
  filter(am_sid %in% ca_cells$am_sid)

ca_mammals <- ca_spp %>%
  filter(order == 'Cetacea') %>%
  mutate(sciname = paste(genus, species, sep = '_'))
ca_mammal_cells <- ca_cells %>%
  filter(am_sid %in% ca_mammals$am_sid)

### make rasters
r_list <- vector('list', length = nrow(ca_mammals)) %>%
  setNames(ca_mammals$sciname)
for(i in 1:nrow(ca_mammals)) {
  sid <- ca_mammals$am_sid[i]
  spp <- ca_mammals$sciname[i]
  cells <- ca_mammal_cells %>%
    filter(am_sid == sid)
  spp_rast <- subs(ca_rast, cells, by = 'loiczid', which = 'prob')
  r_list[[i]] <- spp_rast
}

r_stack <- stack(r_list)
writeRaster(r_stack, bylayer = TRUE, filename = paste0('for_allison/', names(r_stack), '.tif'))

x <- r_stack
values(x)[values(x) < .5] <- NA
y <- x / x

z <- calc(y, sum, na.rm = TRUE)
plot(z)
