\name{CAP_stability}
\alias{CAP_stability}
\title{Explore repeatability of local explanations}
\description{Explore repeatability of local explanations.}
\usage{
CAP_stability(x_train, instance, predict_fn, method = "LIME",
              runs = 10, top_k = 4, num_samples = 1000, seed = 42, ...)
}
\arguments{
\item{x_train}{Numeric predictor matrix with observations in rows.}
\item{instance}{Numeric vector containing one observation to explain.}
\item{predict_fn}{Function accepting a numeric matrix and returning one finite prediction per row.}
\item{method}{Either "LIME" or "OPTILIME".}
\item{runs}{Number of independent neighborhood draws, at least 2.}
\item{top_k}{Number of top-ranked terms compared between explanations.}
\item{num_samples}{Neighborhood size per run.}
\item{seed}{Starting integer random seed.}
\item{...}{Additional parameters supplied to CAP_LIME.}
}
\value{A list containing VSI, CSI and explanations.}
\details{VSI here is mean pairwise Jaccard overlap of selected feature terms. CSI is a descriptive table of coefficient mean, standard deviation, and coefficient of variation, not the standard confidence-interval based CSI from published LIME-stability literature.}
\examples{
x <- matrix(rnorm(120), ncol = 2)
colnames(x) <- c("x1", "x2")
f <- function(z) rowSums(z)
s <- CAP_stability(x, x[1, ], f, runs = 3, top_k = 2,
                   num_samples = 80)
s$VSI
}
