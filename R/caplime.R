# CAP-LIME: Conic Adaptive Piecewise LIME

# Convert input to a numeric matrix and preserve readable variable names.
as_features <- function(x) {
  x <- as.matrix(x)
  if (!is.numeric(x)) stop("Predictors must be numeric.")
  storage.mode(x) <- "double"
  if (is.null(colnames(x))) colnames(x) <- paste0("X", seq_len(ncol(x)))
  if (nrow(x) == 0L || ncol(x) == 0L) stop("Predictors must have rows and columns.")
  if (anyNA(x) || any(!is.finite(x))) stop("Predictor values must be finite numbers.")
  x
}

# Solve ridge regression. The first coefficient can be left unpenalized.
fit_ridge <- function(x, y, lambda = 1, weights = NULL, intercept = TRUE) {
  x <- as.matrix(x)
  y <- as.numeric(y)
  if (intercept) x <- cbind("(Intercept)" = 1, x)
  if (is.null(weights)) weights <- rep(1, nrow(x))
  if (length(y) != nrow(x) || length(weights) != nrow(x)) stop("Incompatible input lengths.")
  if (length(lambda) != 1L || !is.finite(lambda) || lambda < 0 ||
      any(!is.finite(weights)) || any(weights < 0) || sum(weights) <= 0)
    stop("Lambda must be finite and nonnegative; weights must be finite, nonnegative and not all zero.")
  if (any(!is.finite(y))) stop("Response values must be finite.")
  # Minimize sum(w * (y - X b)^2) + lambda * sum(b^2).
  penalty <- diag(lambda, ncol(x))
  if (intercept) penalty[1, 1] <- 0
  xtwx <- crossprod(x, x * weights)
  xtwy <- crossprod(x, y * weights)
  coef <- as.numeric(solve(xtwx + penalty + diag(1e-9, ncol(x)), xtwy))
  names(coef) <- colnames(x)
  predictions <- as.numeric(x %*% coef)
  list(coefficients = coef, fitted = predictions)
}

# Weighted coefficient of determination (R-squared).
local_r2 <- function(y, fitted, weights = NULL) {
  if (is.null(weights)) weights <- rep(1, length(y))
  average <- weighted.mean(y, weights)
  total <- sum(weights * (y - average)^2)
  if (total < 1e-12) return(NA_real_)
  1 - sum(weights * (y - fitted)^2) / total
}

# Build first-order hinge functions, with optional pairwise products.
# Knots are fixed during training and reused for new observations.
hinge_basis <- function(x, knots, degree = 1) {
  x <- as_features(x)
  terms <- list()
  term_names <- character()
  feature_index <- integer()
  for (j in seq_len(ncol(x))) {
    for (knot in knots[[j]]) {
      terms[[length(terms) + 1]] <- pmax(0, x[, j] - knot)
      term_names <- c(term_names, paste0(colnames(x)[j], " > ", signif(knot, 4)))
      feature_index <- c(feature_index, j)
      terms[[length(terms) + 1]] <- pmax(0, knot - x[, j])
      term_names <- c(term_names, paste0(colnames(x)[j], " < ", signif(knot, 4)))
      feature_index <- c(feature_index, j)
    }
  }
  first_count <- length(terms)
  if (degree >= 2 && first_count > 1) {
    # Only combine basis functions from two different variables.
    for (i in seq_len(first_count - 1)) {
      for (j in (i + 1):first_count) {
        if (feature_index[i] != feature_index[j]) {
          terms[[length(terms) + 1]] <- terms[[i]] * terms[[j]]
          term_names <- c(term_names, paste(term_names[i], "x", term_names[j]))
        }
      }
    }
  }
  if (length(terms) == 0) return(matrix(numeric(), nrow(x), 0))
  out <- do.call(cbind, terms)
  colnames(out) <- make.unique(term_names)
  out
}

# Ridge least squares is equivalent to their unconstrained convex quadratic
# objective; no numerical conic solver is required for this special case.
fit_CAP_model <- function(x, y, lambda = 5, num_knots = 5, degree = 1) {
  x <- as_features(x)
  y <- as.numeric(y)
  if (length(y) != nrow(x) || any(!is.finite(y))) stop("y must contain one finite value per row of x.")
  if (length(num_knots) != 1L || !is.finite(num_knots) || num_knots < 1 || num_knots != as.integer(num_knots)) stop("num_knots must be a positive integer.")
  if (length(degree) != 1L || is.na(degree) || !degree %in% c(1, 2)) stop("degree must be 1 or 2.")
  knots <- lapply(seq_len(ncol(x)), function(j) {
    seq(min(x[, j]), max(x[, j]), length.out = num_knots + 2)[-c(1, num_knots + 2)]
  })
  basis <- hinge_basis(x, knots, degree)
  fit <- fit_ridge(basis, y, lambda = lambda)
  structure(list(knots = knots, coefficients = fit$coefficients,
                 names = colnames(x), degree = degree), class = "CAP_model")
}

predict_CAP_model <- function(model, newdata, probability = FALSE) {
  x <- as_features(newdata)
  if (ncol(x) != length(model$names)) stop("Incorrect number of columns.")
  colnames(x) <- model$names
  basis <- hinge_basis(x, model$knots, model$degree)
  prediction <- as.numeric(cbind(1, basis) %*% model$coefficients)
  if (probability) return(pmin(1, pmax(0, prediction)))
  prediction
}

# Explain a single observation with a local surrogate.
# Supported choices are LIME and OPTILIME.
CAP_LIME <- function(x_train, instance, predict_fn, method = "LIME",
                     num_samples = 2000, lambda = 1, kernel_width = NULL,
                     target_r2 = 0.70, seed = 42) {
  x_train <- as_features(x_train)
  instance <- as.numeric(instance)
  p <- ncol(x_train)
  if (length(instance) != p) stop("instance needs one value per predictor.")
  if (!is.function(predict_fn)) stop("predict_fn must be a function.")
  if (length(num_samples) != 1L || !is.finite(num_samples) ||
      num_samples < 10 || num_samples != as.integer(num_samples))
    stop("num_samples must be an integer of at least 10.")
  if (any(!is.finite(instance))) stop("instance must be finite.")
  method <- toupper(method)
  if (!method %in% c("LIME", "OPTILIME")) stop("method must be LIME or OPTILIME.")
  set.seed(seed)
  scales <- apply(x_train, 2, sd)
  scales[!is.finite(scales) | scales < 1e-10] <- 1
  noise <- matrix(rnorm(num_samples * p), ncol = p)
  neighborhood <- sweep(noise, 2, scales, "*")
  neighborhood <- sweep(neighborhood, 2, instance, "+")
  neighborhood[1, ] <- instance
  colnames(neighborhood) <- colnames(x_train)
  y <- as.numeric(predict_fn(neighborhood))
  if (length(y) != num_samples || any(!is.finite(y))) stop("predict_fn must return one finite prediction per row.")
  centered <- sweep(neighborhood, 2, instance, "-")
  design <- centered
  distances <- sqrt(rowSums((sweep(centered, 2, scales, "/"))^2))
  if (is.null(kernel_width)) kernel_width <- sqrt(p) * 0.75
  if (length(kernel_width) != 1L || !is.finite(kernel_width) || kernel_width <= 0)
    stop("kernel_width must be finite and positive.")
  candidates <- if (method == "OPTILIME") seq(3, 0.1, length.out = 15) else kernel_width
  fit_one <- function(width) {
    w <- exp(-(distances^2) / width^2)
    fit <- fit_ridge(design, y, lambda, weights = w, intercept = TRUE)
    predicted <- fit$fitted
    list(fit = fit, weights = w, r2 = local_r2(y, predicted, w), width = width)
  }
  result <- NULL
  for (width in candidates) {
    candidate <- fit_one(width)
    result <- candidate
    if (method != "OPTILIME" || (!is.na(candidate$r2) && candidate$r2 >= target_r2)) break
  }
  coefficients <- result$fit$coefficients
  coefficients <- coefficients[names(coefficients) != "(Intercept)"]
  effects <- data.frame(feature = names(coefficients), coefficient = as.numeric(coefficients))
  effects <- effects[order(abs(effects$coefficient), decreasing = TRUE), , drop = FALSE]
  rownames(effects) <- NULL
  list(method = method, instance_prediction = y[1], local_r2 = result$r2,
       kernel_width = result$width, effects = effects)
}

# Repeat local explanations to quantify sampling stability.
CAP_stability <- function(x_train, instance, predict_fn, method = "LIME",
                          runs = 10, top_k = 4, num_samples = 1000, seed = 42, ...) {
  if (length(runs) != 1L || !is.finite(runs) || runs < 2 || runs != as.integer(runs))
    stop("runs must be an integer of at least 2.")
  if (length(top_k) != 1L || !is.finite(top_k) || top_k < 1 ||
      top_k != as.integer(top_k)) stop("top_k must be a positive integer.")
  results <- lapply(seq_len(runs), function(i) {
    CAP_LIME(x_train, instance, predict_fn, method = method,
             num_samples = num_samples, seed = seed + i - 1, ...)
  })
  terms <- results[[1]]$effects$feature
  coeff <- sapply(results, function(a) a$effects$coefficient[match(terms, a$effects$feature)])
  rownames(coeff) <- terms
  selected <- lapply(results, function(a) head(a$effects$feature, top_k))
  pairs <- combn(runs, 2)
  jaccard <- apply(pairs, 2, function(ix) {
    a <- selected[[ix[1]]]; b <- selected[[ix[2]]]
    length(intersect(a, b)) / length(union(a, b))
  })
  means <- rowMeans(coeff)
  standard_deviations <- apply(coeff, 1, sd)
  list(VSI = mean(jaccard),
       CSI = data.frame(feature = terms, mean_coefficient = means,
                        sd_coefficient = standard_deviations,
                        cv = standard_deviations / (abs(means) + 1e-8), row.names = NULL),
       explanations = results)
}

# Draw an easy-to-read coefficient plot for one explanation.
plot_CAP_LIME <- function(explanation, top_n = 15) {
  if (!is.list(explanation) || is.null(explanation$effects))
    stop("explanation must be the result of CAP_LIME().")
  d <- head(explanation$effects, top_n)
  barplot(rev(d$coefficient), names.arg = rev(d$feature), horiz = TRUE,
          las = 1, col = ifelse(rev(d$coefficient) < 0, "tomato", "seagreen3"),
          main = paste("CAP-LIME:", explanation$method), xlab = "Local coefficient")
  abline(v = 0)
}
