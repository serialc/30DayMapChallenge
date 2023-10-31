library(rjson)

colh <- rjson::fromJSON(file='CoL_hygiene_ratings.json')

# only want restaurants with score breakdown and geocode
valid <- sapply(colh$EstablishmentCollection$EstablishmentDetail, function(x) { 
  length(unlist(x$scores)) == 3 && !any(sapply(x$geocode, is.null))
})

colhdf <- data.frame(
  do.call('rbind', lapply(colh$EstablishmentCollection$EstablishmentDetail[valid], function(x) { 
    # x <- colh$EstablishmentCollection$EstablishmentDetail[valid][[1]]
    c(x$BusinessName,
      as.integer(x$RatingValue),
      as.integer(unlist(x$scores)),
      sum(as.integer(unlist(x$scores))),
      as.numeric(unlist(x$geocode)))
  })), stringsAsFactors = F)

colnames(colhdf) <- c('name', 'rating', 'hygiene', 'structural', 'conf_manage', 'demerits', 'long', 'lat')

write.table(colhdf, file = 'CoL_hygiene_ratings_valid.csv', quote = FALSE, sep=';;', row.names = FALSE)
