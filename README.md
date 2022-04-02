# NOTE: UPDATED SINCE PUBLICATION

This repository has been updated since the publication of  in Ecosphere.  If you are looking for the data and code to support that publication, see:

* `publication` branch here: https://github.com/mapping-marine-spp-vuln/spp_vuln_framework/tree/publication
* Release v1.0.0 here: https://github.com/mapping-marine-spp-vuln/spp_vuln_framework/releases/tag/v1.0.0

## What has been updated?

The updates since publication retool the analysis to downfill and gapfill traits, rather than vulnerability scores.  Because the original project was based largely on species traits provided by taxonomic experts, sometimes at the species level, but sometimes at higher taxonomic ranks or based on representative species (i.e., a species that is more broadly representative of an entire genus, family, or order), imputation and gapfilling was used to expand the scoring for more species.

The new analysis is based on filling of traits rather than calculated vulnerability scores, allowing for additional trait sources to be included at finer taxonomic resolution prior to calculating vulnerability scores, allowing for the vulnerability score of a particular species to be calculated partly from species-specific information and partly from information provided at higher taxonomic ranks.  

Additional traits scored at species level include thermal tolerances (from AquaMaps thermal envelopes), max body size, fecundity, age to maturity (from FishBase/SeaLifeBase), and EOO range (calculated from species range maps).  The FB/SLB traits are not comprehensive; the thermal ranges cover all AquaMaps species but not necessarily those mapped in IUCN; EOO range is comprehensive across all mapped species.

These traits include those most likely to vary within a taxonomic group, so capturing species-specific values where available improves the quality of the vulnerability scoring when taxonomic imputation is required.

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

# Prior release and publication info

Butt, N., Halpern, B. S., O’Hara, C. C., Allcock, A. L., Polidoro, B., Sherman, S., Byrne, M., Birkeland, C., Dwyer, R. G., Frazier, M., Woodworth, B. K., Arango, C. P., Kingsford, M. J., Udyawer, V., Hutchings, P., Scanes, E., McClaren, E. J., Maxwell, S. M., Diaz-Pulido, G., … Klein, C. J. (2022). A trait-based framework for assessing the vulnerability of marine species to human impacts. Ecosphere, 13(2), e3919. https://doi.org/10.1002/ecs2.3919

## Abstract

Marine species and ecosystems are widely affected by anthropogenic stressors, ranging from pollution and fishing to climate change. Comprehensive assessments of how species and ecosystems are impacted by anthropogenic stressors are critical for guiding conservation and management investments.
Previous global risk or vulnerability assessments have focused on marine habitats, or on limited taxa or specific regions. However, information about the susceptibility of marine species across a range of taxa to different stressors everywhere is required to predict how marine biodiversity will respond to human pressures.
We present a novel framework that uses life-history traits to assess species’ vulnerability to a stressor, which we compare across more than 44,000 species from 12 taxonomic groups (classes). Using expert elicitation and literature review, we assessed every combination of each of 42 traits and 22 anthropogenic stressors to calculate each species’ or representative species group’s sensitivity and adaptive capacity to stressors, and then used these assessments to derive their overall relative vulnerability.
The stressors with the greatest potential impact were related to biomass removal (e.g., fisheries), pollution, and climate change. The taxa with the highest vulnerabilities across the range of stressors were mollusks, corals, and echinoderms, while elasmobranchs had the highest vulnerability to fishing-related stressors.
Traits likely to confer vulnerability to climate change stressors were related to the presence of calcium carbonate structures, and whether a species exists across the interface of marine, terrestrial, and atmospheric realms.
Traits likely to confer vulnerability to pollution stressors were related to planktonic state, organism size, and respiration. Such a replicable, broadly applicable method is useful for informing ocean conservation and management decisions at a range of scales, and the framework is amenable to further testing and improvement.
Our framework for assessing the vulnerability of marine species is the first critical step toward generating cumulative human impact maps based on comprehensive assessments of species, rather than habitats.
