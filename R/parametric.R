## take design matrix and returns a factor for parameter matching
## NA --> 0
## other unique values will be factor levels
.mat2fac <- function(m) {
    K <- nrow(m)
    m[upper.tri(m)] <- m[lower.tri(m)]
    m <- factor(as.character(m))
    attr(m, "K") <- K
    m
}

## takes a named param vector and reconstructs matrix
.vec2mat <- function(parm, fac) {
    x <- matrix(0, attr(fac, "K"), attr(fac, "K"))
    fac <- droplevels(fac)
    if (!all(sort(names(parm)) == sort(levels(fac))))
        stop("names of parm and levels of fact must match")
    for (i in names(parm))
        x[!is.na(fac) & fac == i] <- parm[i]
    x
}

.SigmaK_fit <- function(SigmaKstar, H, pattern, init,
method = "Nelder-Mead", control = list()) {
    K <- nrow(SigmaKstar)
    if (any(is.na(diag(pattern))))
        stop("pattern matrix must have parameters in the diagonal")
    if (dim(pattern)[1L] != dim(pattern)[1L])
        stop("pattern matrix must be square matrix")
    pattern1 <- pattern
    pattern1[] <- NA
    diag(pattern1) <- diag(pattern)
    pattern0 <- pattern
    diag(pattern0) <- NA
    fac <- .mat2fac(pattern) # all parms
    lev1 <- levels(.mat2fac(pattern1)) # parms in diag
    lev0 <- levels(.mat2fac(pattern0)) # parms off-diag
    if (length(intersect(lev1, lev0)) > 0)
        stop("diagonal and off-diagonal parameters must not overlap")
    p <- nlevels(droplevels(fac))
    ## make sure diags are >0
    ## generate random starting values using runif()
    init0 <- structure(numeric(p), names=levels(fac))
    if (missing(init)) {
        init0[lev1] <- runif(length(lev1))
    } else {
        init <- init[names(init) %in% names(init0)]
        init0[names(init)] <- init
    }
    if (any(init0[lev1] <= 0))
        stop("inits for diagonal elements must be > 0")
    ## check sparseness
    tmp <- init0
    tmp[] <- 1
    UNK <- sum(.vec2mat(tmp, fac))
    if (UNK > K*(K-1)/2)
        stop(sprintf(
            "number of nonzero cells (%s) in pattern matrix must be <= %s",
            UNK, K*(K-1)/2))
    num_max <- .Machine$double.xmax^(1/3)
    ## we might need constraints here, i.e. >0 diag values
    fun <- function(parms){
        SigmaK <- .vec2mat(parms, fac)
        if (any(diag(SigmaK) <= 0))
            return(num_max)
        10^4 * max((SigmaKstar - (H %*% SigmaK %*% H))^2)
    }
    if (!is.null(control$fnscale) && control$fnscale < 0)
        stop("control$fnscale can not be negative")
    o <- suppressWarnings({
        optim(init0, fun, method=method, control=control, hessian=FALSE)
    })
    o$init <- init0
    o$SigmaK <- .vec2mat(o$par, fac)
    o$method <- method
    o$control <- control
    o
}

SigmaK_fit <- function(object, pattern, ...) {
    o <- .SigmaK_fit(object$SigmaKstar, object$H, pattern, ...)
    object$SigmaK <- o$SigmaK
    o$SigmaK <- NULL
    object$pattern <- pattern
    object$results <- o
    class(object) <- c("edma_fit_p", "edma_fit")
    object
}