library(taxize)

test_spp2 <- 'balaena mysticetus'
z <- classification(test_spp2, db = 'worms')[[1]]
# # A tibble: 14 x 3
#    name               rank            id
#    <chr>              <chr>        <int>
#  1 Animalia           Kingdom          2
#  2 Chordata           Phylum        1821
#  3 Vertebrata         Subphylum   146419
#  4 Gnathostomata      Superclass    1828
#  5 Tetrapoda          Superclass    1831
#  6 Mammalia           Class         1837
#  7 Theria             Subclass    380416
#  8 Cetartiodactyla    Order       370511
#  9 Cetancodonta       Suborder    370545
# 10 Cetacea            Infraorder    2688
# 11 Mysticeti          Superfamily 148724
# 12 Balaenidae         Family      136978
# 13 Balaena            Genus       137012
# 14 Balaena mysticetus Species     137086

### get downstream using the class ID returned
downstream(1837, db = 'worms', downto = 'order', marine_only = FALSE)[[1]]
#        id            name  rank
# 1 1451682 Didelphimorphia order

downstream('mammalia', db = 'worms', downto = 'family')[[1]]
# data frame with 0 columns and 0 rows
children('mammalia', db = 'worms')
children(380416, db = 'worms')

classification('Dugong dugon', db = 'worms')

x <- downstream(1837, db = "worms", downto = "species", marine_only = FALSE)

x <- children(939, db = 'worms')[[1]]
# downstream(939, db = 'worms', downto = 'species')[[1]]

id_vec <- x$childtaxa_id
id_vec_out <- vector('numeric')
rank_vec_out <- vector('character')
for(id in id_vec) {
  y <- tryCatch(children(id, db = 'worms')[[1]], error = function(e) 'umm1', finally = 'umm2')
  print(y)
  if(y != 'umm1') {
    id_vec_out <- c(id_vec_out, y$childtaxa_id)
    rank_vec_out <- c(rank_vec_out, unique(y$childtaxa_rank))
  }
}
unique(rank_vec_out) ### "Genus"

id_vec_out2 <- vector('numeric')
rank_vec_out2 <- vector('character')
for(id in id_vec_out) {
  y <- tryCatch(children(id, db = 'worms')[[1]], error = function(e) 'umm1', finally = 'umm2')
  # print(y)
  if(y != 'umm1') {
    id_vec_out2 <- c(id_vec_out2, y$childtaxa_id[y$childtaxa_id != 'Species'])
    rank_vec_out2 <- c(rank_vec_out2, unique(y$childtaxa_rank))
    if(any(is.na(y$childtaxa_rank))) stop('NA value found: ', id)
  }
}
unique(rank_vec_out2) ### "Species"  "Subgenus"
downstream(147147, db = 'worms', downto = 'species')

### checking unmatched spp
classification('avicennia marina', db = 'worms')
x <- children(182757, db = 'worms', downto = 'order')[[1]]
