assemble_worms <- function(aspect = 'wide') {
  ### Note: this drops all kingdoms but Animalia 
  p_from_k <- read_csv(here('int/phylum_from_kingdom_worms.csv')) %>%
    filter(!is.na(id))
  c_from_p <- read_csv(here('int/class_from_phylum_worms.csv')) %>%
    filter(!is.na(id))
  o_from_c <- read_csv(here('int/order_from_class_worms.csv')) %>%
    filter(!is.na(id))
  f_from_o <- read_csv(here('int/family_from_order_worms.csv')) %>%
    filter(!is.na(id))
  g_from_f <- read_csv(here('int/genus_from_family_worms.csv')) %>%
    filter(!is.na(id))
  s_from_g <- read_csv(here('int/species_from_genus_worms.csv')) %>%
    filter(!is.na(id))
  
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
    distinct()
  
  spp_wide <- disambiguate_species(spp_wide)
  
  if(aspect == 'long') {
    
    ### make that long, but keeping structure for each species
    spp_long <- spp_wide %>%
      mutate(spp = species) %>%
      gather(rank, name, phylum:species) %>%
      mutate(rank = factor(rank, levels = rank_lvls))
    return(spp_long)
    
  } else {
    
    return(spp_wide)
    
  }
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
