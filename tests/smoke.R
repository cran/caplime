# Basic functional tests, including both piecewise degrees.
library(caplime)
set.seed(8)
x <- matrix(rnorm(240), ncol = 3)
colnames(x) <- c("Age", "BMI", "Glucose")
y <- as.numeric(x[, 1] + x[, 2]^2 / 3 > 0)

for (degree_value in c(1, 2)) {
  model <- fit_CAP_model(x, y, num_knots = 2, degree = degree_value)
  stopifnot(inherits(model, "CAP_model"), identical(model$degree, degree_value))
  p <- predict_CAP_model(model, x[1:4, , drop = FALSE], probability = TRUE)
  stopifnot(length(p) == 4L, all(is.finite(p)), all(p >= 0 & p <= 1))
  stopifnot(isTRUE(all.equal(p, predict(model, x[1:4, , drop = FALSE], probability = TRUE))))
  pred <- function(z) predict_CAP_model(model, z, probability = TRUE)
  for (name in c("LIME", "OPTILIME")) {
    out <- CAP_LIME(x, x[1, ], pred, method = name, num_samples = 150)
    stopifnot(identical(out$method, name), is.data.frame(out$effects),
              nrow(out$effects) == ncol(x), is.finite(out$instance_prediction),
              is.finite(out$kernel_width), length(out$local_r2) == 1L)
  }
}

pred <- function(z) rowSums(z)
st <- CAP_stability(x, x[1, ], pred, method = "LIME", runs = 3, num_samples = 150)
stopifnot(st$VSI >= 0, st$VSI <= 1, nrow(st$CSI) == 3)
cat("Both degree tests and both explanation modes passed.\n")
