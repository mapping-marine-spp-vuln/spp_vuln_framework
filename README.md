# Code and data for "A trait-based framework for assessing the vulnerability of marine species to human impacts" 

by Butt, Nathalie; Halpern, Benjamin; O'Hara, Casey; Allcock, Louise; Polidoro, Beth; Sherman, Samantha; Byrne, Maria; Birkeland, Charles; Dwyer, Ross; Frazier, Melanie; Woodworth, Brad; Arango, Claudia; Kingsford, Michael; Udwayer, Vinay; Hutchings, Pat; Scanes, Elliot; McLaren, Emily Jane; Maxwell, Sara; Diaz-Pulido, Guillermo; Dugan, Emma; Simmons, Blake; Wenger, Amelia; Klein, Carissa.

## Abstract

Marine species and ecosystems are widely affected by anthropogenic stressors, ranging from pollution and fishing to climate change. Comprehensive assessments of how species and ecosystems are impacted by anthropogenic stressors are critical for guiding conservation and management investments.
While previous global assessments of risk or vulnerability have focused on habitats, insights into how susceptibility to different stressors varies at a species level are required to predict how biodiversity will change under human pressure. We present a novel framework that uses life-history traits to assess species’ vulnerability to stressors, which we compare across ~32,000 species from 12 taxonomic groups.
Using expert elicitation and literature review, we assessed every combination of each of 42 traits and 22 anthropogenic stressors to calculate each species’ or species group’s sensitivity and adaptive capacity to stressors, and then use these assessments to derive their overall relative vulnerability.
The stressors with the greatest potential impact were related to biomass removal, pollution, and climate change. The taxa with the highest vulnerabilities across the range of stressors were molluscs, corals, and echinoderms, while elasmobranchs had the highest vulnerability to fishing-related stressors. Traits likely to confer vulnerability to climate change stressors were related to the presence of calcium carbonate structures, and whether a species exists across the interface of marine, terrestrial, and atmospheric realms. Traits likely to confer vulnerability to pollution stressors were to do with planktonic state, organism size and respiration. Such a replicable, broadly applicable method is useful for informing ocean conservation and management decisions at a range of scales. Our framework for assessing the vulnerability of marine species is the first critical step towards generating cumulative human impact maps focused on species, rather than habitats.

## Organization of repository

### Main scripts

The .Rmd scripts in the root directory should be run in numeric order.  Briefly:

* `0_clean_species_trait_sheets.Rmd` standardizes idiosyncracies among the various sheets within the species trait workbook, such as typos, differences in spelling or punctuation, or non-standardized entries.
* `1_process_spp_trait_data.Rmd` compares traits in species-trait workbook to acceptable values on stressor-trait spreadsheet. 
    * Saves a file of species matched with valid trait values: `_data/spp_traits_valid.csv`
* `2_calculate_spp_gp_vuln.Rmd` combines species traits with stressor trait scores to calculate sensitivity, general adaptive capacity, specific adaptive capacity, and exposure potential modifier for each species group for which we have been given traits data.  
    * Note that for species groups for which multiple possible trait values were given, a Monte Carlo approach was used to calculate a distribution of possible vulnerability scores for each stressor, and the mean and standard deviation were recorded.
* `3_expand_taxa.Rmd` queries the WoRMS database using the `taxize` package to complete taxonomic tree information for each species or taxon for which traits were provided.  
    * This information is used to assign higher-level taxonomic ranks to the species level in script 4, and to perform the "upstream-downstream" gapfill in script 5.
* `4_downstream_taxa_vuln.Rmd` applies vulnerabilities calculated at the genus/family/higher rank downward to all species included in that group.  
    * The assumption here is that if a taxonomic expert provided information at the family level (e.g.), then vulnerability calculated based on those values should apply to all species within that family, and not counted as "gapfilling" but rather as direct matches.  
    * Note that for each species, the lowest rank of data was used to fill the downstream values; if given at species level, then that was retained; if given at both genus and family, then genus values would be used; etc.
* `5_upstream_downstream_gapfill_vuln.Rmd` gapfills missing species values by assigning an aggregated mean/sd value based on related species.
    * For unmatched species in a genus, scores for all direct-matched species in that genus are aggregated ("upstream") to calculate a genus mean/sd, and that is used to fill the unmatched species ("downstream").
    * If after the genus-level fill, there remain unmatched species in a family, then all direct-matched species in that family are aggregated upstream as for genus, and those are used to fill unmatched species downstream.
* `6_plot_spp_vuln.Rmd` summarizes the resulting data in a variety of data visualizations to be used in the manuscript and supplement.

### Folder structure

* `_raw_data` includes all the data novel to this project, including expert-provided traits for a range of taxa, and sensitivity/adaptive capacity scores for traits across a range of stressors.
* `_data` includes data processed from the `_raw_data` for use in analysis.
* `_output` includes final products at various stages:
    * `spp_gp_vuln_w_distribution.csv` includes, for each species group and stressor, the intermediate values for sensitivity, adaptive capacity, etc used to reach the final vulnerability score.  This is provided only for species groups at the level provided by taxonomic experts, i.e., scores at genus/family/etc level are not yet downfilled to the species level.
    * `vuln_gapfilled_score.csv` provides a mean vulnerability score for each stressor for each species included in the assessment (after downward matching and upstream/downstream gapfilling).  Use the `vuln_gf_id` to join this table to the `sd` and `tx` tables.
    * `vuln_gapfilled_sd.csv` provides a standard deviation of vulnerability score for each stressor for each species included in the assessment.
    * `vuln_gapfilled_tx.csv` provides taxonomic information for each species included in the assessment, including the level at which it was originally matched (for direct matches including downward matching) or gapfilled (for species scored via upstream-downstream gapfilling).
* `ms_figs` includes figures generated by script 6 for consideration in the manuscript and SI.
* `figs` includes auto-generated figures for other scripts; these are for data exploration purposes, not for inclusion in manuscript.
* `int` includes intermediate files saved during computationally intensive scripts to avoid re-processing and to save time.  These files may be used in multiple scripts.
* `tmp` is similar to `int` but includes very raw temporary files that are only used in a single script.