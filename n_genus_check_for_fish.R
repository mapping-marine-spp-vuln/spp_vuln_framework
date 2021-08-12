library(tidyverse)
library(here)
fnums <- read_csv(here('temp_fish_nums.csv')) %>%
  mutate(species = str_trim(tolower(species)),
         genus = str_remove_all(species, ' .+')) %>%
  group_by(genus) %>%
  filter(!all(is.na(n_repr_genus))) %>%
  mutate(n_repr_genus = ifelse(is.na(n_repr_genus), 1, n_repr_genus)) %>%
  select(-species) %>%
  summarize(n_repr_genus = sum(n_repr_genus))

tx <- read_csv(here('_output/vuln_gapfilled_tx.csv'))


fnums_g <- inner_join(tx, fnums, by = 'genus') %>%
  filter(class == 'actinopterygii') %>%
  group_by(genus, n_repr_genus) %>%
  summarize(n_in_genus = n_distinct(species))

fnums_missing <- fnums %>%
  filter(!genus %in% fnums_g$genus)

DT::datatable(fnums_g)

knitr::kable(fnums_g)
