\name{predict_CAP_model}
\alias{predict_CAP_model}
\alias{predict.CAP_model}
\title{Predict from a fitted piecewise model}
\description{Predict a numeric outcome from a CAP model.}
\usage{
predict_CAP_model(model, newdata, probability = FALSE)
\method{predict}{CAP_model}(object, newdata, ...)
}
\arguments{
\item{model}{Fitted CAP_model object.}
\item{object}{Fitted CAP_model object.}
\item{newdata}{Numeric matrix with predictor columns in their training order.}
\item{probability}{If TRUE, clip predictions to the range zero to one.}
\item{...}{Additional arguments forwarded to predict_CAP_model, such as probability.}
}
\value{A numeric vector of predictions.}
\details{Clipping values to zero and one does not guarantee probability calibration.}
\examples{
x <- matrix(rnorm(80), ncol = 2)
colnames(x) <- c("a", "b")
model <- fit_CAP_model(x, rowSums(x), num_knots = 2)
predict(model, x[1:3, , drop = FALSE])
}
