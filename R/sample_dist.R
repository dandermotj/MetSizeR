#' Split data into random groups
#'
#'
#'@param n Number of observations to be grouped
#'@param probs A named vector of probabilities for groups
#'

random_group <- function(n, probs) {
  probs <- probs / sum(probs)
  g <- findInterval(seq(0, 1, length = n), c(0, cumsum(probs)),
                    rightmost.closed = TRUE)
  names(probs)[sample(g)]
}

#' Generate n random splits of a data frame
#'
#' Generate n random splits of a data frame
#'
#' @param df a data frame
#' @inheritParams random_group

partition <- function(df, n, probs) {
  replicate(n, split(df, random_group(nrow(df), probs)), FALSE) %>%
    transpose() %>%
    as_data_frame()
}

#' Sample from the null distribution
#'
#' Computes pooled/corrected standard deviations and associated
#' t-statistics from random samples. The function returns a data frame
#' where each row denote a simulation and columns denote the pooled
#' standard deviation, corrected standard deviation and the associated
#' t-statistic. Given a sample of n variables, then each cell is a
#' list of n numbers, for example the pooled standard deviation for
#' each variable.
#'
#' @param x       a numeric dataframe
#' @param n_sims  number of simulations
#' @param n1      number of samples in treatment A
#' @param n2      number of samples in treatment B
#'
#' @return a data frame of list columns
#'
#' @examples
#' # simulate 100 split samples of the iris dataset and compute
#' # variances and test statistics
#' sample_dist(iris[-5], 100, 10, 9, 3)

sample_dist <- function(x, n_sims, n1, n2, conf_idx){

  probs <- c(A = n1, B = n2)
  sd_fun <- function(A, B) { sqrt((1/n1 + 1/n2) * ((n1 - 1)*diag(var(A)) + (n2 - 1)*diag(var(B))) / (n1 + n2 - 2)) }
  t_stat_fun <- function(A, B, corr_sd) {(colMeans(A) - colMeans(B)) / corr_sd}

  partition(x, n_sims, probs) %>% transmute(
    pooled_sd = map2(A, B, sd_fun),
    corr_sd = map(pooled_sd, ~ .x + sort(.x)[conf_idx]),
    t_stat = list(A = A, B = B, corr_sd = corr_sd) %>%
      pmap(t_stat_fun)
  )
}

