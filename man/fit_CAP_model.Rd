\name{fit_CAP_model}
\alias{fit_CAP_model}
\title{Fit ridge-penalized piecewise hinge regression}
\description{Fit ridge-penalized piecewise hinge regression.}
\usage{
fit_CAP_model(x, y, lambda = 5, num_knots = 5, degree = 1)
}
\arguments{
\item{x}{Numeric matrix of predictors.}
\item{y}{Numeric outcome vector.}
\item{lambda}{Nonnegative ridge penalty.}
\item{num_knots}{Positive integer number of evenly spaced knots per feature.}
\item{degree}{Either 1 for main-effect hinge terms or 2 for pairwise hinge products.}
}
\value{A CAP_model object with knots, coefficients, predictor names and interaction degree.}
\details{A simple piecewise ridge model fitted by linear algebra. Here conic refers to the source project name; this implementation has no explicit conic constraint. Large degrees and knot counts can create very large design matrices.}
\examples{
x <- matrix(rnorm(80), ncol = 2)
colnames(x) <- c("a", "b")
y <- x[, 1]^2 + x[, 2]
model <- fit_CAP_model(x, y, num_knots = 2)
head(predict_CAP_model(model, x))
}
