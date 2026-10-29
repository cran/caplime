\name{plot_CAP_LIME}
\alias{plot_CAP_LIME}
\title{Draw ranked local-effect coefficients}
\description{Draw ranked local-effect coefficients.}
\usage{
plot_CAP_LIME(explanation, top_n = 15)
}
\arguments{
\item{explanation}{Result returned by CAP_LIME.}
\item{top_n}{Number of highest-ranked features to display.}
}
\value{Draws a base graphics bar plot; returns the result from barplot invisibly or as a graphics side effect.}
\details{Signed regression coefficients are shown on their original feature scales.}
\examples{
x <- matrix(rnorm(100), ncol = 2)
colnames(x) <- c("a", "b")
f <- function(z) rowSums(z)
result <- CAP_LIME(x, x[1, ], f, num_samples = 80)
plot_CAP_LIME(result)
}
