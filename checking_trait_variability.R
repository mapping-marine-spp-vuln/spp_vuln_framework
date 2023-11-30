library(oharac) ### remotes::install_github('oharac/oharac')
library(tidyverse)
library(here)

source(here('common_fxns.R'))


spp_traits <- get_spp_traits()

zxcv <- spp_traits %>% 
  group_by(taxon, category, trait, trait_value) %>% 
  summarize(n_instances = sum(trait_prob), .groups = 'drop')

asdf <- zxcv %>% 
  group_by(taxon, trait) %>% 
  summarize(coef_var = ifelse(n() == 1, 0, sd(n_instances) / mean(n_instances)))

qwer <- asdf %>% 
  group_by(trait) %>% 
  summarize(m = mean(coef_var), .groups = 'drop') %>% 
  arrange(m)

xx <- asdf %>% 
  mutate(trait = factor(trait, levels = qwer$trait))

ggplot(xx, aes(x = coef_var, y = trait)) + geom_boxplot()


### plot variation in scores for trait values
str_trait_f <- here('_raw_data/xlsx',
                    'stressors_traits_scored.xlsx')

assign_rank_scores <- function(x) {
  y <- tolower(as.character(x))
  z <- case_when(!is.na(as.numeric(x)) ~ as.numeric(x),
                 str_detect(y, '^na')  ~ 0.00,
                 str_detect(y, '^n')   ~ 0.00, ### none, NA, no
                 str_detect(y, '^lo')  ~ 0.33,
                 str_detect(y, '^med') ~ 0.67,
                 str_detect(y, '^hi')  ~ 1.00,
                 str_detect(y, '^y')   ~ 1.00, ### yes
                 TRUE                  ~ NA_real_) ### basically NA
  return(z)
}

s_traits_raw <- readxl::read_excel(str_trait_f, sheet = 'sensitivity') 
a_traits_raw <- readxl::read_excel(str_trait_f, sheet = 'spec_adcap') 
g_traits_raw <- readxl::read_excel(str_trait_f, sheet = 'gen_adcap')

s_traits_df <- s_traits_raw %>%
  janitor::clean_names() %>%
  gather(stressor, s_score, -category, -trait, -trait_value) %>%
  mutate(s_score_orig = as.character(s_score),
         s_score = assign_rank_scores(s_score)) %>%
  filter(!is.na(s_score)) %>%
  group_by(trait) %>%
  summarize(sd_score = sd(s_score))

a_traits_df <- a_traits_raw %>%
  janitor::clean_names() %>%
  gather(stressor, a_score, -category, -trait, -trait_value) %>%
  mutate(a_score_orig = as.character(a_score),
         a_score = assign_rank_scores(a_score)) %>%
  filter(!is.na(a_score))

g_traits_df <- g_traits_raw %>%
  janitor::clean_names() %>%
  gather(stressor, g_score, -category, -trait, -trait_value) %>%
  mutate(g_score_orig = as.character(g_score),
         g_score = assign_rank_scores(g_score)) %>%
  filter(!is.na(g_score))
