assemble_worms <- function(aspect = 'wide', seabirds_only = FALSE, am_patch = TRUE) {
  ### Note: this drops all kingdoms but Animalia 
  p_from_k <- read_csv(here('int/expand1_phylum_from_kingdom_worms.csv'), 
                       col_types = c(id = 'i')) %>%
    filter(!is.na(id))
  c_from_p <- read_csv(here('int/expand2_class_from_phylum_worms.csv'), 
                       col_types = c(id = 'i')) %>%
    filter(!is.na(id))
  o_from_c <- read_csv(here('int/expand3_order_from_class_worms.csv'), 
                       col_types = c(id = 'i')) %>%
    filter(!is.na(id))
  f_from_o <- read_csv(here('int/expand4_family_from_order_worms.csv'), 
                       col_types = c(id = 'i')) %>%
    filter(!is.na(id))
  g_from_f <- read_csv(here('int/expand5_genus_from_family_worms.csv'), 
                       col_types = c(id = 'i')) %>%
    filter(!is.na(id))
  s_from_g <- read_csv(here('int/expand6_species_from_genus_worms.csv'), 
                       col_types = c(id = 'i')) %>%
    filter(!is.na(id))
  
  if(am_patch) {
    am_patch_long <- read_csv(here('int/expand7_aquamaps_patch.csv'),
                              col_types = cols(.default = 'c')) %>%
      select(spp_gp, rank, name) %>%
      distinct()
  
    am_patch_wide <- am_patch_long %>%
      distinct() %>%
      spread(rank, name) %>%
      select(-spp_gp) %>%
      distinct() %>% mutate(source = 'am')
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
    spp_df <- spp_df %>%
      mutate(spp = species) %>%
      gather(rank, name, phylum:species) %>%
      mutate(rank = factor(rank, levels = rank_lvls))

  }
  return(spp_df)
}

resolve_am_disputes <- function(spp_wide) {
  ## coerce AM classifications to match WoRMS
  dupes_g <- show_dupes(spp_wide %>%
                          select(-species) %>%
                          distinct(),
                        'genus') %>%
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
    mutate(family = case_when(genus  == 'leptocephalus' ~ 'congridae',
                              family == 'archaeobalanidae' ~ 'balanidae',
                              TRUE ~ family)) %>%
    mutate(order = case_when(order  == 'arcoida'     ~ 'arcida',
                             family == 'balanidae'   ~ 'balanomorpha',
                             family == 'veneridae'   ~ 'venerida',
                             family == 'planaxidae'  ~ '[unassigned] caenogastropoda',
                             family == 'hermaeidae'  ~ 'sacoglossa',
                             family == 'sabellidae'  ~ 'sabellida',
                             family == 'cerithiidae' ~ '[unassigned] caenogastropoda',
                             family == 'epitoniidae' ~ '[unassigned] caenogastropoda',
                             family == 'pyrgomatidae'    ~ 'balanomorpha',
                             family == 'tjaernoeiidae'   ~ 'not assigned',
                             family == 'pyramidellidae'  ~ 'neogastropoda',
                             family == 'ophiacanthidae'  ~ 'ophiacanthida',
                             family == 'poecilasmatidae' ~ 'scalpellomorpha',
                             family == 'plakobranchidae' ~ 'sacoglossa',
                             family == 'gorgonocephalidae' ~ 'euryalida',
                             TRUE ~ order)) %>%
    mutate(class  = ifelse(class == 'maxillopoda', 'thecostraca', class)) %>%
    distinct()
  
  dupes_g_force_nonworms <- spp_wide %>%
    filter(genus %in% dupes_g$genus & !genus %in% worms_fill$genus) %>%
    rowwise() %>%
    mutate(family = nonworms_fill$family[genus == nonworms_fill$genus],
           order  = nonworms_fill$order[genus  == nonworms_fill$genus],
           class  = nonworms_fill$class[genus  == nonworms_fill$genus]) %>%
    ungroup() %>%
    distinct()
  
  spp_wide_am_resolved <- spp_wide %>%
    filter(!genus %in% dupes_g$genus) %>%
    bind_rows(dupes_g_force_worms, dupes_g_force_nonworms) %>%
    select(-source)
  
  return(spp_wide_am_resolved)
}

disambiguate_species <- function(spp_wide) {
  
  dupes <- spp_wide %>%
    oharac::show_dupes('species')
  ### no more duplicates?
  
  spp_wide_nodupes <- spp_wide %>%
    filter(!species %in% dupes$species)

  dupes_fixed <- dupes %>%
    mutate(keep = case_when(genus == 'pinctada' & order == 'ostreida'         ~ TRUE,
                            family == 'margaritidae' & order == 'trochida' & genus != 'pinctada' ~ TRUE,
                            genus == 'atractotrema' & class == 'gastropoda'   ~ TRUE,
                            genus == 'chaperia' & phylum == 'bryozoa'         ~ TRUE,
                            family == 'molgulidae' & genus == 'eugyra'        ~ TRUE,
                            genus == 'aturia' & order == 'nautilida'          ~ TRUE,
                            genus == 'spongicola' & family == 'spongicolidae' ~ TRUE,
                            genus == 'stictostega' & family == 'hippothoidae' ~ TRUE,
                            genus == 'favosipora' & family == 'densiporidae'  ~ TRUE,
                            genus == 'cladochonus' & family ==  'pyrgiidae'   ~ TRUE,
                            genus == 'bathya' & order == 'amphipoda'          ~ TRUE,
                            genus == 'bergia' & family == 'drepanophoridae'   ~ TRUE,
                            genus == 'geminella' & family == 'catenicellidae' ~ TRUE,
                            genus == 'ctenella' & family ==  'ctenellidae'    ~ TRUE,
                            genus == 'nematoporella' & family ==  'arthrostylidae' ~ TRUE,
                            genus == 'pleurifera' & family == 'columbellidae' ~ TRUE,
                            genus == 'philippiella' & family == 'steinmanellidae' ~ TRUE,
                            genus == 'thoe' & family == 'mithracidae'         ~ TRUE,
                            genus == 'trachyaster' & family == 'palaeostomatidae' ~ TRUE,
                            genus == 'diplocoenia' & family == 'acroporidae'  ~ TRUE,
                            genus == 'versuriga' & family == 'versurigidae'   ~ TRUE,
                            genus == 'tremaster' & family == 'asterinidae'    ~ TRUE,
                            genus == 'distefanella' & family == 'radiolitidae' ~ TRUE,
                            TRUE ~ FALSE)) %>%
    filter(keep) %>%
    select(-keep) %>%
    distinct()

  spp_wide_clean <- bind_rows(spp_wide_nodupes, dupes_fixed)
  
  return(spp_wide_clean)
}
