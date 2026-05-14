To join files into a complete set of vulnerability scores per species and stressor (conceptual example in R):

junction_df <- data.table::fread('spp_vuln_junction.csv')
strs_df     <- data.table::fread('spp_vuln_stressor_lookup.csv')
taxa_df     <- data.table::fread('spp_vuln_taxa_lookup.csv')

vuln_df     <-  junction_df %>%
  dplyr::left_join(strs_df, by = 'vuln_str_id') %>%
  dplyr::left_join(taxa_df, by = 'aphia_id') %>%
  dplyr::select(-vuln_str_id)
