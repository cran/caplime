# Input validation for the two supported explanation methods.
library(caplime)
set.seed(1)
x <- matrix(rnorm(100), ncol = 2)
colnames(x) <- c("a", "b")
for (d in c(1, 2)) {
  model <- fit_CAP_model(x, rowSums(x), num_knots = 2, degree = d)
  stopifnot(inherits(model, "CAP_model"))
  stopifnot(length(predict_CAP_model(model, x[1:3, , drop = FALSE])) == 3L)
}
stopifnot(inherits(try(CAP_LIME(x, x[1, ], function(z) rowSums(z),
                                 num_samples = 5), silent = TRUE), "try-error"))
stopifnot(inherits(try(CAP_LIME(x, x[1, ], function(z) rowSums(z),
                                 method = "BAYLIME"), silent = TRUE), "try-error"))
stopifnot(inherits(try(fit_CAP_model(x, rowSums(x), degree = 3),
                     silent = TRUE), "try-error"))
