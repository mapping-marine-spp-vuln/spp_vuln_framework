library(taxize)
library(tidyverse)

check_status <- function(check_ids) {
  check_ids <- check_ids[!is.na(check_ids)]
  n_chunks <- ceiling(length(check_ids) / 50)
  records_list <- vector('list', length = n_chunks)
  for(i in 1:n_chunks) {
    indices <- ((i-1)*50 + 1):min(i*50, length(check_ids))
    ids_chunk <- check_ids[indices]
    ids_param <- paste0('aphiaids[]=', ids_chunk, collapse = '&')
    records_url <- paste0('https://www.marinespecies.org/rest/AphiaRecordsByAphiaIDs?', ids_param)
    records_list[[i]] <- jsonlite::fromJSON(records_url) %>%
      select(id = AphiaID, sciname = scientificname, status) %>%
      distinct()
  }
  records_df <- records_list %>% 
    bind_rows()
  return(records_df)
}

ds_check <- function(id, downto) {
  x <- downstream(id, db = 'worms', downto = downto)[[1]] %>%
    mutate(status = check_status(id))
}


test_spp <- 'planctoteuthis'
classification(test_spp, db = 'worms')[[1]]

# 13 Balaenoptera        Genus       137013
# 14 Balaenoptera brydei Species     242603
(ds_check(11767, 'genus'))
