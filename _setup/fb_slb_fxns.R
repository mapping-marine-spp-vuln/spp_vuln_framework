#######################################################.
#### Helper functions for FishBase and SeaLifeBase ####
#######################################################.
get_fb_slb <- function(fxn = species, 
                       keep_cols = NULL, keep_fxn = contains, 
                       drop_cols = NULL, drop_fxn = all_of) {
  fb <- fxn(server = 'fishbase') %>%
    janitor::clean_names() %>%
    mutate(db = 'fb')
  slb <- fxn(server = 'sealifebase') %>%
    janitor::clean_names() %>%
    mutate(db = 'slb')
  if(!is.null(keep_cols)) {
    fb <- fb %>%
      dplyr::select(spec_code, species, db, keep_fxn(keep_cols))
    slb <- slb %>%
      dplyr::select(spec_code, species, db, keep_fxn(keep_cols))
  }
  if(!is.null(drop_cols)) {
    fb <- fb %>%
      dplyr::select(-drop_fxn(drop_cols))
    slb <- slb %>%
      dplyr::select(-drop_fxn(drop_cols))
  }
  ### sometimes class of a column from one server mismatches that of the other.
  ### This should only be a problem for character vs. numeric - i.e.,
  ### not a problem for numeric vs. integer
  cols_check <- data.frame(
    type_fb = sapply(fb, class) %>% sapply(first),
    col = names(fb)) %>%
    inner_join(data.frame(
      type_slb = sapply(slb, class) %>% sapply(first),
      col = names(slb))) %>%
    filter(type_fb != type_slb) %>%
    filter(type_fb == 'character' | type_slb == 'character')
  if(nrow(cols_check) > 0) {
    message('Conflicting column types; coercing all to character:')
    message(cols_check)
    fb <- fb %>%
      mutate(across(all_of(cols_check$col), as.character))
    slb <- slb %>%
      mutate(across(all_of(cols_check$col), as.character))
  }
  
  return(bind_rows(fb, slb) %>% mutate(species = tolower(species)))
}

#####################################################.
####  Resolve names using WoRMS API fuzzy match  ####
#####################################################.

fuzzy_match <- function(spp_vec, marine_only = TRUE) {
  
  spp_fix <- str_replace_all(spp_vec, ' +', '%20')
  spp_arg <- paste0('scientificnames[]=', spp_fix, collapse = '&')
  
  mar_flag <- tolower(as.character(marine_only))
  matchname_stem <- 'https://www.marinespecies.org/rest/AphiaRecordsByMatchNames?%s&marine_only=%s'
  matchname_url  <- sprintf(matchname_stem, spp_arg, mar_flag)
  
  Sys.sleep(0.25) ### slight pause for API etiquette
  match_records <- try(jsonlite::fromJSON(matchname_url)) 
  if(class(match_records) == 'try-error') {
    match_df <- data.frame(orig_sciname = spp_vec,
                           valid_name = 'no match',
                           aphia_id = -9999) 
    return(match_df)
  } else {
    match_df <- match_records %>%
      setNames(spp_vec) %>%
      bind_rows(.id = 'orig_sciname')
    
    still_unmatched <- data.frame(orig_sciname = spp_vec) %>%
      filter(!orig_sciname %in% match_df$orig_sciname) %>%
      mutate(valid_name = 'no match', aphia_id = -9999)
    out_df <- match_df %>%
      bind_rows(still_unmatched) %>%
      select(orig_sciname, valid_name, aphia_id = valid_AphiaID) %>%
      mutate(valid_name = tolower(valid_name))
    return(out_df)
  }
}

collect_records <- function(fb_df, field, file_tag, force = FALSE) {
  
  ### get names with values that don't match WoRMS names
  spp_from_worms <- assemble_worms()
  
  fb_df <- fb_df %>%
    rename(tmp := !!field)
  
  no_match <- anti_join(fb_df, spp_from_worms, by = 'species')
  no_match_w_vals <- no_match %>%
    filter(!is.na(tmp)) %>%
    mutate(genus = str_extract(species, '^[a-z]+(?= ?)'),
           genus_match = genus %in% spp_from_worms$genus)
  
  # table(no_match_w_vals %>% select(genus_match, db))
  
  names_to_resolve <- no_match_w_vals %>%
    filter(genus_match) %>%
    .$species %>% unique() %>% sort()
  
  ### Define file and check whether it exists
  aphia_records_csv <- sprintf(here('int/%s.csv'), file_tag)
  
  
  if(!file.exists(aphia_records_csv) | force) {
    
    chunk_size <- 25
    n_chunks <- ceiling(length(names_to_resolve) / chunk_size)
    record_chunk_stem <- 'tmp/%s_chunk_%s_%s.csv'
    
    if(force) {
      unlink(list.files(here('tmp'), pattern = sprintf('%s_chunk', file_tag), full.names = TRUE))
    }
    
    for(i in 1:n_chunks) { ### i <- 1
      message('Processing chunk ', i, ' of ', n_chunks)
      i_start <- (i-1) * chunk_size + 1
      i_end   <- min(i * chunk_size, length(names_to_resolve))
      chunk_csv <- here(sprintf(record_chunk_stem, file_tag, i_start, i_end))
      if(file.exists(chunk_csv)) {
        message('Chunk exists: ', basename(chunk_csv), '... skipping!')
        next()
      }
      spp_vec <- names_to_resolve[i_start:i_end]
      chunk_df <- fuzzy_match(spp_vec, marine_only = FALSE)
      write_csv(chunk_df, chunk_csv)
    }
    
    chunk_fs <- list.files(here('tmp'), pattern = sprintf('%s_chunk', file_tag), full.name = TRUE)
    record_df <- parallel::mclapply(chunk_fs, data.table::fread) %>%
      bind_rows() %>%
      distinct()
    write_csv(record_df, aphia_records_csv)
  }
  record_df <- data.table::fread(aphia_records_csv) %>%
    clean_scinames('valid_name')
}

clean_scinames <- function(df, field) {
  ### eliminate confounding clutter in taxonomic names
  df_clean <- df %>%
    rename(tmp := !!field) %>%
    mutate(tmp = str_remove_all(tmp, '\\(.+?\\)'), ### parentheticals
           tmp = str_remove_all(tmp, '\\[.+?\\]'), ### brackets
           tmp = str_remove_all(tmp, '[^a-z ]')) %>% ### punctuation
    mutate(tmp = str_squish(tmp)) %>%
    rename(!!field := tmp)
}
