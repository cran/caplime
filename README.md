# caplime: Conic Adaptive Piecewise LIME

`caplime` provides an educational R implementation of piecewise ridge regression
with first- or second-degree hinge bases, and local surrogate explanations.
The available local explanation modes are **LIME** and **OPTILIME** only.
The main explanation function is `CAP\_LIME()`.

## Installation from the package folder

In RStudio, install `devtools` once if necessary. Then open the package project
folder (the one containing `DESCRIPTION`) and run:

```r
install.packages("devtools")
devtools::install("/path/to/caplime", dependencies = FALSE)
library(caplime)
```

Or build the CRAN source archive by running `R CMD build caplime` from the
parent directory, and install the resulting `caplime\_0.1.0.tar.gz`.

## Local explanations: LIME and OPTILIME

```r
library(caplime)
set.seed(1)
x <- matrix(rnorm(300), ncol = 3)
colnames(x) <- c("a", "b", "c")
f <- function(newx) newx\[, 1] + newx\[, 2]^2

lime\_result <- CAP\_LIME(x, x\[1, ], f, method = "LIME", num\_samples = 200)
opti\_result <- CAP\_LIME(x, x\[1, ], f, method = "OPTILIME", num\_samples = 200)
print(head(lime\_result$effects))
print(head(opti\_result$effects))
plot\_CAP\_LIME(lime\_result)
```

## Piecewise model: both degree settings

```r
set.seed(2)
y <- x\[, 1]^2 + x\[, 2]
model\_degree1 <- fit\_CAP\_model(x, y, num\_knots = 2, degree = 1)
model\_degree2 <- fit\_CAP\_model(x, y, num\_knots = 2, degree = 2)
head(predict\_CAP\_model(model\_degree1, x))
head(predict\_CAP\_model(model\_degree2, x))
```

## Testing

Run `devtools::check("/path/to/caplime", cran = TRUE)` in RStudio.
The test scripts under `tests/` exercise both `degree = 1` and `degree = 2`,
and both local explanation modes.

## Scientific scope

The piecewise model uses ridge-penalized least squares with hinge basis
functions, not an explicit conic solver. The OPTILIME mode searches a fixed
set of bandwidth values to meet a local R-squared target; it is a simplified
variant and does not reproduce the complete published OptiLIME procedure.
`CAP\_stability()` returns a descriptive coefficient-variation table (CSI),
not an inferential confidence-interval-based CSI. 

