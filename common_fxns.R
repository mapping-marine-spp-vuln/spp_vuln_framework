assemble_worms <- function(aspect = 'wide', seabirds = TRUE) {
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
  
  am_patch_long <- read_csv(here('int/expand7_aquamaps_patch.csv'),
                            col_types = cols(.default = 'c')) %>%
    select(spp_gp, rank, name) %>%
    distinct()

  am_patch_wide <- am_patch_long %>%
    distinct() %>%
    spread(rank, name) %>%
    select(-spp_gp) %>%
    distinct()
  
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
    select(kingdom, phylum, class, order, family, genus, species) %>%
    filter(kingdom == 'animalia') %>%
    select(-kingdom) %>%
    bind_rows(am_patch_wide) %>%
    distinct()
  
  spp_df <- disambiguate_species(spp_wide)
  
  if(seabirds == TRUE) {
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

disambiguate_species <- function(spp_wide) {
  dupes <- spp_wide %>%
    show_dupes('species')
  spp_wide_nodupes <- spp_wide %>%
    filter(!species %in% dupes$species)
  ### named vector of 
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
    select(-keep)
  # dupes_fixed2 <- dupes %>%
  #   filter(!species %in% dupes_fixed$species)
  # dupes_fixed$keep %>% sum()
  # dupes$species %>% n_distinct()
  
  spp_wide_clean <- bind_rows(spp_wide_nodupes, dupes_fixed)
}
