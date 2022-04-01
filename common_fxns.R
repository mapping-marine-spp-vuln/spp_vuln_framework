here_anx <- function(f = '', ...) { 
  ### create file path to git-annex dir for project
  f <- paste(f, ..., sep = '/')
  f <- stringr::str_replace_all(f, '\\/+', '/')
  f_anx <- sprintf('/home/shares/ohi/spp_vuln/spp_vuln_framework/%s', f)
  return(f_anx)
}

assemble_worms <- function(aspect = 'wide', seabirds_only = TRUE, am_patch = TRUE) {
  ### Note: this drops all kingdoms but Animalia 
  
  p_from_k <- data.table::fread(here('int', 
                                     'expand1_phylum_from_kingdom_worms.csv')) %>%
    filter(!is.na(id)) %>%
    select(-id) %>%
    distinct()
  c_from_p <- data.table::fread(here('int', 
                                     'expand2_class_from_phylum_worms.csv')) %>%
    filter(!is.na(id)) %>%
    select(-id) %>%
    distinct()
  o_from_c <- data.table::fread(here('int', 
                                     'expand3_order_from_class_worms.csv')) %>%
    filter(!is.na(id)) %>%
    select(-id) %>%
    distinct()
  f_from_o <- data.table::fread(here('int', 
                                     'expand4_family_from_order_worms.csv')) %>%
    filter(!is.na(id)) %>%
    select(-id) %>%
    distinct()
  g_from_f <- data.table::fread(here('int', 
                                     'expand5_genus_from_family_worms.csv')) %>%
    filter(!is.na(id)) %>%
    select(-id) %>%
    distinct()
  s_from_g <- data.table::fread(here('int', 
                                     'expand6_species_from_genus_worms.csv')) %>%
    filter(!is.na(id)) %>%
    select(-id) %>%
    distinct()
  
  if(am_patch) {
    am_patch_wide <- data.table::fread(here('int',
                                            'expand7_aquamaps_patch.csv')) %>%
      distinct() %>% 
      mutate(source = 'am')
  } else {
    am_patch_wide <- data.frame(source = 'am') ### blank dataframe for bind_rows
  }
  
  rank_lvls <- c('kingdom', 'phylum', 'class', 'order', 'family', 'genus', 'species')
  
  ### create wide for complete classification for each species
  spp_wide <- s_from_g %>%
    select(genus = parent, species = name) %>%
    left_join(g_from_f %>% select(family = parent, genus = name), 
              by = c('genus')) %>%
    left_join(f_from_o %>% select(order = parent, family = name), 
              by = c('family')) %>%
    left_join(o_from_c %>% select(class = parent, order = name), 
              by = c('order')) %>%
    left_join(c_from_p %>% select(phylum = parent, class = name), 
              by = c('class')) %>%
    left_join(p_from_k %>% select(kingdom = parent, phylum = name),
              by = c('phylum')) %>%
    select(phylum, class, order, family, genus, species) %>%
    mutate(source = 'worms') %>%
    bind_rows(am_patch_wide) %>%
    filter(phylum %in% p_from_k$name) %>%
    ### since p_from_k only includes Animalia, this phylum selection drops
    ### AquaMaps non-animalia phyla, e.g., chlorophytes, cyanobacteria, plants
    clean_scinames('species') %>%
    clean_scinames('genus') %>%
    clean_scinames('family') %>%
    clean_scinames('order') %>%
    clean_scinames('class') %>%
    clean_scinames('phylum') %>%
    distinct()
  
  spp_wide_disambiguated <- disambiguate_species(spp_wide)
  
  spp_wide_am_resolved <- resolve_am_disputes(spp_wide_disambiguated)
  
  ### disambiguate "not assigned" - these appear at order and class levels; 
  ### this would only matter when doing upstream/downstream imputation at 
  ### order/class levels...
  spp_df <- spp_wide_am_resolved %>%
    mutate(class = ifelse(class == 'not assigned', paste(phylum, 'not assigned'), class),
           order = ifelse(order == 'not assigned', paste(class, 'not assigned'), order))
  
  
  if(seabirds_only == TRUE) {
    seabird_list <- readxl::read_excel(here('_raw_data/xlsx/species_numbers.xlsx'),
                                       sheet = 'seabirds', skip = 1) %>%
      janitor::clean_names() %>%
      select(spp = scientific_name_fixed) %>%
      filter(!is.na(spp)) %>%
      mutate(spp = tolower(spp) %>% str_trim) %>%
      .$spp
    spp_df <- spp_df %>%
      filter(!(tolower(class) == 'aves' & !tolower(species) %in% seabird_list))
  }
  
  if(aspect == 'long') {
    
    ### make that long, but keeping structure for each species
    spp_df_long <- spp_df %>%
      mutate(spp = species) %>%
      gather(rank, name, phylum:species) %>%
      mutate(rank = factor(rank, levels = rank_lvls))
    return(spp_df_long)
    
  } else {
    
    return(spp_df)
    
  }
}

resolve_am_disputes <- function(spp_wide) {
  ## coerce AM classifications to match WoRMS
  dupes_g <- show_dupes(spp_wide %>%
                          select(-species) %>%
                          distinct(),
                        'genus') %>%
    filter(!(genus == 'gammarus' & family == 'paratanaidae')) %>%
    group_by(genus) %>%
    filter(n_distinct(class) > 1 | n_distinct(order) > 1 | n_distinct(family) > 1) %>%
    mutate(am_count = sum(source == 'am'),
           non_am_count = sum(source == 'worms'))
  ### identify duplicated genera that are included (uniquely) in WoRMS
  worms_fill <- dupes_g %>%
    filter(non_am_count > 0) %>%
    filter(source == 'worms')
  
  dupes_g_force_worms <- spp_wide %>%
    filter(genus %in% worms_fill$genus) %>%
    rowwise() %>%
    mutate(family = worms_fill$family[genus == worms_fill$genus],
           order  = worms_fill$order[genus == worms_fill$genus],
           class  = worms_fill$class[genus == worms_fill$genus]) %>%
    ungroup()
  
  nonworms_fill <- dupes_g %>%
    filter(!genus %in% dupes_g_force_worms$genus) %>%
    mutate(genus  = case_when(genus == 'lamellaria'    ~ 'lamellidea',
                              genus == 'leptocephalus' ~ 'conger',
                              TRUE ~ genus)) %>%
    mutate(family = case_when(genus == 'conger'        ~ 'congridae',
                              genus == 'cerithiella'   ~ 'newtoniellidae',
                              genus == 'elysia'        ~ 'plakobranchidae',
                              genus == 'euciroa'       ~ 'euciroidae',
                              genus == 'eulimastoma'   ~ 'pyramidellidae',
                              genus == 'lamellidea'    ~ 'achatinellidae',
                              genus == 'mathilda'      ~ 'mathildidae',
                              genus == 'polybranchia'  ~ 'hermaeidae',
                              genus == 'tjaernoeia'    ~ 'tjaernoeiidae',
                              genus == 'lamellitrochus' ~ 'solariellidae',
                              TRUE ~ family)) %>%
    mutate(order = case_when(genus == 'lamellitrochus' ~ 'trochida',
                             genus == 'elysia' ~ 'sacoglossa',
                             genus == 'eulimastoma' ~ 'pylopulmonata',
                             genus == 'conger' ~ 'anguilliformes',
                             genus == 'polybranchia' ~ 'sacoglossa',
                             genus == 'tjaernoeia' ~ '[unassigned] euthyneura',
                             TRUE ~ order)) %>%
    mutate(class = case_when(order == 'sacoglossa' ~ 'gastropoda',
                             TRUE ~ class)) %>%
    mutate(phylum = case_when(class == 'gastropoda' ~ 'mollusca',
                              TRUE ~ class)) %>%
    distinct()
  
  dupes_g_force_nonworms <- spp_wide %>%
    filter(genus %in% dupes_g$genus & !genus %in% worms_fill$genus) %>%
    rowwise() %>%
    mutate(genus  = case_when(genus == 'lamellaria'    ~ 'lamellidea',
                              genus == 'leptocephalus' ~ 'conger',
                              TRUE ~ genus)) %>%
    mutate(family = nonworms_fill$family[genus == nonworms_fill$genus],
           order  = nonworms_fill$order[genus  == nonworms_fill$genus],
           class  = nonworms_fill$class[genus  == nonworms_fill$genus],
           phylum = nonworms_fill$phylum[genus == nonworms_fill$genus]) %>%
    ungroup() %>%
    distinct()
  
  spp_wide_am_resolved <- spp_wide %>%
    filter(!genus %in% dupes_g$genus) %>%
    bind_rows(dupes_g_force_worms, dupes_g_force_nonworms) %>%
    select(-source) %>%
    distinct()
  
  return(spp_wide_am_resolved)
}

disambiguate_species <- function(spp_wide) {
  
  dupes <- spp_wide %>%
    oharac::show_dupes('species')
  dupes_drop_source <- dupes %>%
    select(-source) %>%
    distinct() %>%
    show_dupes('species')
  ### currently, none due to appearing in both AM and WoRMS
  
  spp_wide_nodupes <- spp_wide %>%
    filter(!species %in% dupes_drop_source$species)
  
  dupes_fixed <- dupes %>%
    filter(species != 'no match') %>%
    mutate(genus  = ifelse(species == 'praephiline finmarchica', 'praephiline', genus),
           family = ifelse(species == 'praephiline finmarchica', 'laonidae', family),
           genus  = ifelse(species == 'polititapes rhomboides', 'polititapes', genus)) %>%
    mutate(keep = case_when(family == 'margaritidae' & order == 'trochida' & genus != 'pinctada' ~ TRUE,
                            genus  == 'pinctada'     & order == 'ostreida'       ~ TRUE,
                            genus  == 'atractotrema' & class == 'gastropoda'     ~ TRUE,
                            genus  == 'chaperia'     & phylum == 'bryozoa'       ~ TRUE,
                            family == 'molgulidae'   & genus == 'eugyra'         ~ TRUE,
                            genus  == 'aturia'       & order == 'nautilida'      ~ TRUE,
                            genus  == 'spongicola'   & family == 'spongicolidae' ~ TRUE,
                            genus  == 'stictostega'  & family == 'hippothoidae'  ~ TRUE,
                            genus  == 'favosipora'   & family == 'densiporidae'  ~ TRUE,
                            genus  == 'cladochonus'  & family == 'pyrgiidae'     ~ TRUE,
                            genus  == 'bathya'       & order == 'amphipoda'      ~ TRUE,
                            genus  == 'ctenella'     & family == 'ctenellidae'   ~ TRUE,
                            genus  == 'pleurifera'   & family == 'columbellidae' ~ TRUE,
                            genus  == 'thoe'         & family == 'mithracidae'   ~ TRUE,
                            genus  == 'diplocoenia'  & family == 'acroporidae'   ~ TRUE,
                            genus  == 'versuriga'    & family == 'versurigidae'  ~ TRUE,
                            genus  == 'tremaster'    & family == 'asterinidae'   ~ TRUE,
                            genus  == 'distefanella' & family == 'radiolitidae'  ~ TRUE,
                            genus  == 'bracthelia'   & family == 'agatheliidae'  ~ TRUE,
                            genus  == 'dinetia'      & family == 'draconematidae'   ~ TRUE,
                            genus  == 'bergia'       & family == 'drepanophoridae'  ~ TRUE,
                            genus  == 'geminella'    & family == 'catenicellidae'   ~ TRUE,
                            genus  == 'nematoporella' & family == 'arthrostylidae'  ~ TRUE,
                            genus  == 'philippiella' & family == 'steinmanellidae'  ~ TRUE,
                            genus  == 'trachyaster'  & family == 'palaeostomatidae' ~ TRUE,
                            TRUE ~ FALSE)) %>%
    group_by(species) %>%
    mutate(gen_match = str_detect(species, paste0('^', genus, ' ')) & source == 'am',
           keep = ifelse(sum(!keep) > 1 & gen_match, TRUE, keep)) %>%
    filter(keep) %>%
    select(-keep, -gen_match) %>%
    distinct()
  
  spp_wide_clean <- bind_rows(spp_wide_nodupes, dupes_fixed) %>%
    ### a few more instances!
    mutate(order = case_when(family == 'apogonidae' ~ 'kurtiformes',
                             family == 'labridae' ~ 'eupercaria incertae sedis',
                             family == 'ophiacanthidae' ~ 'ophiacanthida',
                             TRUE ~ order))
  return(spp_wide_clean)
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
