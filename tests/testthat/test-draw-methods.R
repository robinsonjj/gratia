## Test draw() methods

## load packages
library("testthat")
library("gratia")
library("mgcv")
library("ggplot2")
library("vdiffr")

context("draw-methods")

## Fit models
set.seed(1)
dat1 <- gamSim(1, n = 400, dist = "normal", scale = 2, verbose = FALSE)
m1 <- gam(y ~ s(x0) + s(x1) + s(x2) + s(x3), data = dat1, method = "REML")

set.seed(1)
dat2 <- gamSim(2, n = 4000, dist = "normal", scale = 1, verbose = FALSE)
m2 <- gam(y ~ s(x, z, k = 40), data = dat2$data, method = "REML")

set.seed(1)
dat3 <- gamSim(4, verbose = FALSE)
m3 <- gam(y ~ fac + s(x2, by = fac) + s(x0), data = dat3)

test_that("draw.evaluated_1d_smooth() plots the smooth", {
    sm <- evaluate_smooth(m1, "s(x2)")
    plt <- draw(sm)
    expect_doppelganger("draw 1d smooth for selected smooth", plt)
})

test_that("draw.gam works with numeric select", {
    plt <- draw(m1, select = 2)
    expect_doppelganger("draw gam smooth for selected smooth numeric", plt)
    plt <- draw(m1, select = c(1,2))
    expect_doppelganger("draw gam smooth for two selected smooths numeric", plt)
})

test_that("draw.gam fails with bad select", {
    expect_error(draw(m1, select = 8),
                 "One or more indices in 'select' > than the number of smooths in the model.",
                 fixed = TRUE)
    expect_error(draw(m1, select = c(1,3,5,6)),
                 "One or more indices in 'select' > than the number of smooths in the model.",
                 fixed = TRUE)
    expect_error(draw(m1, select = c(1,2,3,4,5)),
                 "Trying to select more smooths than are in the model.",
                 fixed = TRUE)
    expect_error(draw(m1, select = TRUE),
                 "When 'select' is a logical vector, 'length(select)' must equal
the number of smooths in the model.", fixed = TRUE)
})

test_that("draw.gam works with character select", {
    plt <- draw(m1, select = "s(x1)")
    expect_doppelganger("draw gam smooth for selected smooth character", plt)
    plt <- draw(m1, select = c("s(x0)", "s(x1)"))
    expect_doppelganger("draw gam smooth for two selected smooths character", plt)
})

test_that("draw.gam works with logical select", {
    plt <- draw(m1, select = c(TRUE, rep(FALSE, 3)))
    expect_doppelganger("draw gam smooth for selected smooth logical", plt)
    plt <- draw(m1, select = rep(c(TRUE, FALSE), each = 2))
    expect_doppelganger("draw gam smooth for two selected smooths logical", plt)
})

test_that("draw.gam works with partial_match", {
    plt <- draw(m3, select = 's(x2)', partial_match = TRUE)
    expect_doppelganger("draw gam with partial match TRUE", plt)
    expect_message(draw(m3, select = 's(x2)', partial_match = FALSE),
                   "Unable to draw any of the model terms.",
                   fixed = TRUE)
})

test_that("draw.gam works with select and parametric", {
    plt <- draw(m3, select = 's(x2)', partial_match = TRUE)
    expect_doppelganger("draw gam with select and parametric is NULL", plt)
    plt <- draw(m3, select = 's(x2)', partial_match = TRUE, parametric = FALSE)
    expect_doppelganger("draw gam with select and parametric is FALSE", plt)
    plt <- draw(m3, select = 's(x2)', partial_match = TRUE, parametric = TRUE)
    expect_doppelganger("draw gam with select and parametric is TRUE", plt)
    plt <- draw(m3, parametric = TRUE)
    expect_doppelganger("draw gam without select and parametric is TRUE", plt)
    plt <- draw(m3, parametric = FALSE)
    expect_doppelganger("draw gam without select and parametric is FALSE", plt)
})

test_that("draw.evaluated_2d_smooth() plots the smooth & SE", {
    sm <- evaluate_smooth(m2, "s(x,z)", n = 100)
    plt <- draw(sm)
    expect_doppelganger("draw 2d smooth", plt)
    plt <- draw(sm, show = "se")
    expect_doppelganger("draw std error of 2d smooth", plt)
})

test_that("draw.gam() plots a simple multi-smooth AM", {
    plt <- draw(m1)
    expect_doppelganger("draw simple multi-smooth AM", plt)

    plt <- draw(m1, scales = "fixed")
    expect_doppelganger("draw simple multi-smooth AM with fixed scales", plt)
})

test_that("draw.gam() plots an AM with a single 2d smooth", {
    plt <- draw(m2)
    expect_doppelganger("draw AM with 2d smooth", plt)

    sm <- evaluate_smooth(m2, smooth = "s(x,z)")
    plt <- draw(sm, show = "se")
    expect_doppelganger("draw evaulated 2d smooth standard errors", plt)
})

test_that("draw.gam() plots an AM with a single factor by-variable smooth", {
    plt <- draw(m3)
    expect_doppelganger("draw AM with factor by-variable smooth", plt)

    plt <- draw(m3, scales = "fixed")
    expect_doppelganger("draw AM with factor by-variable smooth with fixed scales", plt)
})

## simulate date from y = f(x2)*x1 + error
dat <- gamSim(3, n = 400, verbose = FALSE)
mod <- gam(y ~ s(x2, by = x1), data = dat)

test_that("draw() works with continuous by", {
    plt <- draw(mod)
    expect_doppelganger("draw AM with continuous by-variable smooth", plt)
})

test_that("draw() works with continuous by and fixed scales", {
    plt <- draw(mod, scales = "fixed")
    expect_doppelganger("draw AM with continuous by-var fixed scale", plt)
})

test_that("draw() works with random effect smooths (bs = 're')", {
    ## simulate example... from ?mgcv::random.effects
    dat <- gamSim(1, n = 400, scale = 2, verbose = FALSE) ## simulate 4 term additive truth

    fac <- as.factor(sample(1:20, 400, replace = TRUE))
    dat$X <- model.matrix(~ fac - 1)
    b <- rnorm(20) * 0.5
    dat <- transform(dat, y = y + X %*% b)

    rm1 <- gam(y ~ s(fac, bs = "re") + s(x0) + s(x1) + s(x2) +
                   s(x3), data = dat, method = "ML")

    sm <- evaluate_smooth(rm1, "s(fac)")
    expect_s3_class(sm, "evaluated_re_smooth")

    p1 <- draw(sm)
    expect_doppelganger("draw.evaluated_re_smooth", p1)

    p2 <- draw(rm1, ncol = 3)
    expect_doppelganger("draw.gam model with ranef smooth", p2)

    p3 <- draw(rm1, ncol = 3, scales = "fixed")
    expect_doppelganger("draw.gam model with ranef smooth fixed scales", p3)
})

test_that("draw() with random effect smooths (bs = 're') & factor by variable ", {
    ## simulate example...
    set.seed(1)
    df <- gamSim(4, n = 400, scale = 2, verbose = FALSE) ## simulate 4 term additive truth

    ## random effects
    ranef <- as.factor(sample(1:20, 400, replace = TRUE))
    df$X <- model.matrix(~ ranef - 1)
    b <- rnorm(20) * 0.5
    da1 <- transform(df, y = y + X %*% b)

    ## fit model
    rm2 <- gam(y ~ fac + s(ranef, bs = "re", by = fac) + s(x0) + s(x1) + s(x2),
               data = df, method = "ML")

    sm <- evaluate_smooth(rm2, "s(ranef)")
    expect_s3_class(sm, "evaluated_re_smooth")
    p1 <- draw(sm)
    expect_doppelganger("draw.evaluated_re_smooth with factor by", p1)
    p2 <- draw(rm2, ncol = 3)
    expect_doppelganger("draw.gam model with ranef smooth factor by", p2)
    p3 <- draw(rm2, ncol = 3, scales = "fixed")
    expect_doppelganger("draw.gam model with ranef smooth factor by fixed scales", p3)
})

test_that("draw() can handle non-standard names -- a function call as a name", {
    df <- data.frame(y = c(0.15,0.17,0.07,0.17,0.01,0.15,0.18,0.04,-0.06,-0.08,
                           0, 0.03,-0.27,-0.93,0.04,0.12,0.08,0.15,0.04,0.15,
                           0.03,0.09,0.11,0.13,-0.11,-0.32,-0.7,-0.78,0.07,0.04,
                           0.06,0.12,-0.15,0.05,-0.08,0.14,-0.02,-0.14,-0.24,
                           -0.32,-0.78,-0.81,-0.04,-0.25,-0.09,0.02,-0.13,-0.2,
                           -0.04,0,0.02,-0.05,-0.19,-0.37,-0.57,-0.81),
                     time =  rep(2^c(-1, 0, 1, 1.58,2, 2.58, 3, 3.32, 3.58, 4.17,
                                     4.58, 5.58, 6.17, 7.39), 4))
    ## the smooth is of `log2(time)` but this needs special handling
    ## in the `ggplot()` to avoid `ggplot()` looking incorrectly for `time` and
    ## not the correct `log2(time)`
    fit <- gam(y ~ s(log2(time)), data = df, method = "REML")
    p1 <- draw(fit)
    expect_doppelganger("draw.gam model with non-standard names", p1)
})

test_that("draw() works with factor-smooth interactions (bs = 'fs')", {
    ## simulate example... from ?mgcv::factor.smooth.interaction
    set.seed(0)
    ## simulate data...
    f0 <- function(x) 2 * sin(pi * x)
    f1 <- function(x, a=2, b=-1) exp(a * x)+b
    f2 <- function(x) 0.2 * x^11 * (10 * (1 - x))^6 + 10 *
                          (10 * x)^3 * (1 - x)^10
    n <- 500
    nf <- 10
    fac <- sample(1:nf, n, replace=TRUE)
    x0 <- runif(n)
    x1 <- runif(n)
    x2 <- runif(n)
    a <- rnorm(nf) * .2 + 2;
    b <- rnorm(nf) * .5
    f <- f0(x0) + f1(x1, a[fac], b[fac]) + f2(x2)
    fac <- factor(fac)
    y <- f + rnorm(n) * 2

    df <- data.frame(y = y, x0 = x0, x1 = x1, x2 = x2, fac = fac)
    mod <- gam(y~s(x0) + s(x1, fac, bs="fs", k=5) + s(x2, k=20),
               method = "ML")

    sm <- evaluate_smooth(mod, "s(x1,fac)")
    expect_s3_class(sm, "evaluated_fs_smooth")

    p1 <- draw(sm)
    expect_doppelganger("draw.evaluated_fs_smooth", p1)

    p2 <- draw(mod, ncol = 2)
    expect_doppelganger("draw.gam model with fs smooth", p2)

    p3 <- draw(mod, ncol = 2, scales = "fixed")
    expect_doppelganger("draw.gam model with fs smooth fixed scales", p3)
})

test_that("draw() works with parametric terms", {
    set.seed(0)
    ## fake some data...
    f1 <- function(x) {exp(2 * x)}
    f2 <- function(x) {
        0.2*x^11*(10*(1-x))^6+10*(10*x)^3*(1-x)^10
    }
    f3 <- function(x) {x*0}

    n <- 200
    sig2 <- 4
    x0 <- rep(1:4,50)
    x1 <- runif(n, 0, 1)
    x2 <- runif(n, 0, 1)
    x3 <- runif(n, 0, 1)
    e <- rnorm(n, 0, sqrt(sig2))
    y <- 2*x0 + f1(x1) + f2(x2) + f3(x3) + e
    df <- data.frame(x0 = x0, x1 = x1, x2 = x2, x3 = x3, y = y)

    ## fit
    mod <- gam(y ~ x0 + s(x1) + s(x2) + s(x3), data = df)

    ## evaluate parametric terms directly
    e1 <- evaluate_parametric_term(mod, term = "x0")
    expect_s3_class(e1, "evaluated_parametric_term")
    expect_equal(ncol(e1), 7L)
    expect_equal(names(e1), c("term", "type", "value", "partial", "se",
                              "upper", "lower"))
    p1 <- draw(e1)
    expect_doppelganger("draw.evaluated_parametric_term with linear parametric term", p1)

    ## check evaluate_parametric_term works
    p2 <- draw(mod)
    expect_doppelganger("draw.gam with linear parametric term", p2)

    ## factor parametric terms
    x0 <- factor(x0)
    df <- data.frame(x0 = x0, x1 = x1, x2 = x2, x3 = x3, y = y)
    ## fit
    mod <- gam(y ~ x0 + s(x1) + s(x2) + s(x3), data = df)

    ## check evaluate_parametric_term works
    p3 <- draw(mod)
    expect_doppelganger("draw.gam with factor parametric term", p3)

    ## evaluate parametric terms directly
    e2 <- evaluate_parametric_term(mod, term = "x0")
    expect_s3_class(e2, "evaluated_parametric_term")

    expect_error(evaluate_parametric_term(mod, term = "x1"),
                 "Term is not in the parametric part of model: <x1>",
                 fixed = TRUE)

    expect_warning(evaluate_parametric_term(mod, term = c('x0', 'x1')),
                   "More than one `term` requested; using the first <x0>",
                   fixed = TRUE)
})

test_that("component-wise CIs work without seWithMean", {
    sm <- evaluate_smooth(m1, "s(x3)", overall_uncertainty = FALSE)
    plt <- draw(sm)
    expect_doppelganger("draw 1d smooth for selected smooth with overall_uncertainty false", plt)

    plt <- draw(m1, overall_uncertainty = FALSE)
    expect_doppelganger("draw gam with overall_uncertainty false", plt)
})

test_that("draw.derivates() plots derivatives for a GAM", {
    d1 <- derivatives(m1)
    plt <- draw(d1)
    expect_doppelganger("draw derivatives for a GAM", plt)

    plt <- draw(d1, scales = "free")
    expect_doppelganger("draw derivatives for a GAM with fixed scales", plt)
})

## test that issue 39 stays fixed
test_that("draw.gam doesn't create empty plots with multiple parametric terms", {
    set.seed(42)
    dat <- gamSim(4, n = 300, verbose = FALSE)
    dat <- transform(dat, fac = factor(fac), fac2 = factor(fac)) # second factor
    ## GAM with 2 factors and 2 numeric terms
    m2f <- gam(y ~ s(x0) + s(x1) + fac + fac2, data = dat,
               family = gaussian(link = "identity"))
    plt <- draw(m2f)
    expect_doppelganger("draw issue 39 empty plots", plt)
})

test_that("draw.mgcv_smooth() can plot basic smooth bases", {
    set.seed(42)
    dat <- gamSim(1, n = 400, verbose = FALSE)
    bs <- basis(s(x0), data = dat)
    plt <- draw(bs)
    expect_doppelganger("draw basic tprs basis", plt)
})

test_that("draw.mgcv_smooth() can plot by factor basis smooth bases", {
    set.seed(42)
    dat <- gamSim(4, n = 400, verbose = FALSE)
    bs <- basis(s(x2, by = fac), data = dat)
    plt <- draw(bs)
    expect_doppelganger("draw by factor basis", plt)
})

test_that("draw() works with a ziplss models; issue #45", {
    ## simulate some data...
    f0 <- function(x) 2 * sin(pi * x); f1 <- function(x) exp(2 * x)
    f2 <- function(x) 0.2 * x^11 * (10 * (1 - x))^6 + 10 * 
                          (10 * x)^3 * (1 - x)^10
    n <- 500
    set.seed(5)
    x0 <- runif(n)
    x1 <- runif(n)
    x2 <- runif(n)
    x3 <- runif(n)
    
    ## Simulate probability of potential presence...
    eta1 <- f0(x0) + f1(x1) - 3
    p <- binomial()$linkinv(eta1) 
    y <- as.numeric(runif(n) < p) ## 1 for presence, 0 for absence
    
    ## Simulate y given potentially present (not exactly model fitted!)...
    ind <- y > 0
    eta2 <- f2(x2[ind])/3
    y[ind] <- rpois(exp(eta2), exp(eta2))
    df <- data.frame(y, x0, x1, x2, x3)
    b1 <- gam(list(y ~ s(x2) + x3,
                   ~ s(x0) + x1), family = ziplss(), data = df)
    plt <- draw(b1)
    vdiffr::expect_doppelganger("draw ziplss parametric terms issue 45", plt)
})

test_that("draw works for sample_smooths objects", {
    sm1 <- smooth_samples(m1, n = 15, seed = 23478)
    plt <- draw(sm1, alpha = 0.7)
    vdiffr:::expect_doppelganger("draw smooth_samples for GAM m1", plt)
    
    sm2 <- smooth_samples(m2, n = 15, seed = 23478)
    plt <- draw(sm2, alpha = 0.7)
    vdiffr:::expect_doppelganger("draw smooth_samples for GAM m2", plt)
    
    sm3 <- smooth_samples(m3, n = 15, seed = 23478)
    plt <- draw(sm3, alpha = 0.7)
    vdiffr:::expect_doppelganger("draw smooth_samples for GAM m3", plt)
})

test_that("draw works for sample_smooths objects with user specified smooth", {
    sm3 <- smooth_samples(m3, n = 15, seed = 23478)
    plt <- draw(sm3, select = "s(x0)", alpha = 0.7)
    vdiffr:::expect_doppelganger("draw selected smooth_samples for GAM m3", plt)
    
    plt <- draw(sm3, select = "s(x2)", alpha = 0.7, partial_match = TRUE)
    vdiffr:::expect_doppelganger("draw selected factor by smooth_samples for GAM m3", plt)
})
