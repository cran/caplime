\name{CAP_LIME}
\alias{CAP_LIME}
\title{Explain one observation with a local surrogate}
\description{Explain one observation with a local surrogate.}
\usage{
CAP_LIME(x_train, instance, predict_fn, method = "LIME",
         num_samples = 2000, lambda = 1, kernel_width = NULL,
         target_r2 = 0.70, seed = 42)
}
\arguments{
\item{x_train}{Numeric predictor matrix with observations in rows.}
\item{instance}{Numeric vector containing one observation to explain.}
\item{predict_fn}{Function accepting a numeric matrix and returning one finite prediction per row.}
\item{method}{Either "LIME" or "OPTILIME".}
\item{num_samples}{Number of simulated neighbors, at least 10.}
\item{lambda}{Nonnegative ridge penalty.}
\item{kernel_width}{Positive neighborhood weighting bandwidth, or NULL for a default.}
\item{target_r2}{Target local fit for the simplified OPTILIME search.}
\item{seed}{Random seed for repeatability.}
}
\value{A list with method, instance_prediction, local_r2, kernel_width, effects .}
\details{The OPTILIME mode is a simplified educational bandwidth search and not a full reproduction of the published procedure. LIME local coefficients depend on the predictor units. This function is model-agnostic and does not itself fit a conic optimization problem.}
\examples{
x <- matrix(rnorm(120), ncol = 2)
colnames(x) <- c("a", "b")
f <- function(z) z[, 1] + 0.5 * z[, 2]^2
result <- CAP_LIME(x, x[1, ], f, num_samples = 80)
head(result$effects)
}
