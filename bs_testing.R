library(tidyverse)

set.seed(1234)

m <- .02
b <- .05
e <- .02
yrs <- 0:10

df <- data.frame(year = yrs) %>%
  mutate(x = m * year + b + rnorm(n = length(yrs), mean = 0, sd = e))

summary(lm(x ~ year, data = df))
# Call:
#   lm(formula = x ~ year, data = df)
# 
# Residuals:
#   Min        1Q    Median        3Q       Max 
# -0.040306 -0.005281 -0.001615  0.013367  0.027683 
# 
# Coefficients:
#               Estimate Std. Error t value Pr(>|t|)    
#   (Intercept) 0.045232   0.011174   4.048  0.00289 ** 
#   year        0.019387   0.001889  10.265 2.88e-06 ***
#   ---
#   Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1
# 
# Residual standard error: 0.01981 on 9 degrees of freedom
# Multiple R-squared:  0.9213,	Adjusted R-squared:  0.9126 
# F-statistic: 105.4 on 1 and 9 DF,  p-value: 2.878e-06

n_sims <- 1000

set.seed <- 10101
system.time({
  bootstrap_list <- vector('list', length = n_sims)
  for(sim in 1:n_sims) {
    if(sim %% 100 == 0) cat(sim, '... ' )
    bs_df <- sample_n(df, size = nrow(df), replace = TRUE)
    bs_lm <- lm(x ~ year, data = bs_df)
    coeff_df <- broom::tidy(bs_lm)
    bootstrap_list[[sim]] <- coeff_df
  }
  bootstrap_results <- bind_rows(bootstrap_list) %>%
    # filter(p.value < .05) %>%
    group_by(term) %>%
    summarize(mu = mean(estimate), sd = sd(estimate))
}) ### 1000 reps = 5.57 s

  
bootstrap_results
# # A tibble: 2 x 3
#   term            mu      sd
#   <chr>        <dbl>   <dbl>
# 1 (Intercept) 0.0469 0.0142 
# 2 year        0.0192 0.00182

library(car)
set.seed <- 10101
system.time({
  bs_test <- car::Boot(object = lm(x ~ year, data = df), R = n_sims)
}) ### .75 seconds for 1000 reps

summary(bs_test)
# Number of bootstrap replications R = 1000 
#             original   bootBias   bootSE  bootMed
# (Intercept) 0.045232 8.4111e-05 0.013917 0.045385
# year        0.019387 1.7448e-05 0.001791 0.019376