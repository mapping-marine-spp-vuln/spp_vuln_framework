### quick score comparison

library(tidyverse)
library(here)

strs <- c('biomass_removal',
          'water_temp',
          'bycatch',
          'oa',
          'slr',
          'uv',
          'habitat_loss_degradation',
          'wildlife_strike',
          'light_pollution',
          'eutrophication_nutrient_pollution')

v_pub_df <- read_csv(here('vuln_gapfilled_score_pub.csv')) %>%
  inner_join(read_csv(here('vuln_gapfilled_tx_pub.csv'))) %>%
  select(where(is.numeric), -vuln_gf_id, species, taxon) %>%
  pivot_longer(values_to = 'vuln_pub', names_to = 'str', cols = air_temp:wildlife_strike) %>%
  filter(str %in% strs)

v_new_df <- read_csv(here('_output/vuln_gapfilled_score.csv')) %>%
  inner_join(read_csv(here('_output/vuln_gapfilled_tx.csv'))) %>%
  select(where(is.numeric), -vuln_gf_id, species, taxon) %>%
  pivot_longer(values_to = 'vuln_new', names_to = 'str', cols = air_temp:wildlife_strike) %>%
  filter(str %in% strs)

joined <- inner_join(v_pub_df, v_new_df) %>%
  mutate(diff = vuln_new - vuln_pub) 

joined %>%
  group_by(str) %>%
  summarize(m = mean(diff), sd = sd(diff), min = min(diff), max = max(diff), z = sum(diff == 0))

joined %>%
  summarize(m = mean(diff), sd = sd(diff), min = min(diff), max = max(diff), z = sum(diff == 0))
