To join files into a complete set of traits and trait values per species (conceptual example in R):

junction_df  <- data.table::fread('spp_traits_junction.csv')
taxa_df      <- data.table::fread('spp_traits_taxa_lookup.csv')
trait_val_df <- data.table::fread('spp_traits_trait_val_lookup.csv')
gapfill_df   <- data.table::fread('spp_traits_gapfill_levels.csv')

spp_traits_df <-  junction_df %>%
  dplyr::left_join(taxa_df, by = 'aphia_id') %>%
  dplyr::left_join(trait_val_df, by = 'gf_trait_id') %>%
  dplyr::left_join(gapfill_df, by = 'gf_match_id') %>%
  ### drop arbitrary id columns:
  dplyr::select(-gf_match_id, -gf_trait_id)
