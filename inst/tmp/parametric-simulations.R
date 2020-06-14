#remotes::install_github("psolymos/EDMAinR")

set.seed(123)
library(EDMAinR)

M <- array(
  c(82, 21, 22, -50, -37, -37,
  0,  17, -17, 0,  41,  -41),
  dim=c(6, 2),
  dimnames=list(paste0("L", 1:6), c("X", "Y")))

S1 <- matrix(
  c("s", NA,  NA, NA,  NA,  NA,
    NA, "s", NA, NA,  NA,  NA,
    NA,  NA, "s", NA,  NA,  NA,
    NA,  NA,  NA, "s", NA,  NA,
    NA,  NA,  NA, NA, "s", NA,
    NA,  NA,  NA, NA,  NA, "s"),
  nrow=6, ncol=6, byrow=TRUE)
dimnames(S1) <- list(rownames(M), rownames(M))
parm1 <- c("s"=4)

S2 <- matrix(
  c("s1", NA,  NA, NA,  NA,  NA,
    NA, "s2", NA, NA,  NA,  NA,
    NA,  NA, "s2", NA,  NA,  NA,
    NA,  NA,  NA, "s3", NA,  NA,
    NA,  NA,  NA, NA, "s4", NA,
    NA,  NA,  NA, NA,  NA, "s4"),
  nrow=6, ncol=6, byrow=TRUE)
dimnames(S2) <- list(rownames(M), rownames(M))
parm2 <- c("s1"=12, "s2"=2, "s3"=4, "s4"=7)

S3 <- matrix(
  c("s1", NA,  NA, NA,  NA,  NA,
    NA, "s2", NA, NA,  NA,  NA,
    NA,  NA, "s3", NA,  NA,  NA,
    NA,  NA,  NA, "s4", NA,  NA,
    NA,  NA,  NA, NA, "s5", NA,
    NA,  NA,  NA, NA,  NA, "s6"),
  nrow=6, ncol=6, byrow=TRUE)
dimnames(S3) <- list(rownames(M), rownames(M))
parm3 <- c("s1"=12, "s2"=1, "s3"=3, "s4"=4, "s5"=8, "s6"=6)

S4 <- matrix(
  c("s1", "c1", "c1", NA,  NA,  NA,
    "c1", "s1", NA,  NA,  NA,  NA,
    "c1", NA,  "s1", NA,  NA,  NA,
    NA,  NA,  NA,  "s2", "c2", "c2",
    NA,  NA,  NA,  "c2", "s2", NA,
    NA,  NA,  NA,  "c2", NA,  "s2"),
  nrow=6, ncol=6, byrow=TRUE)
dimnames(S4) <- list(rownames(M), rownames(M))
parm4 <- c("s1"=12, "c1"=1, "s2"=8, "c2"=2)

S5 <- matrix(
  c("s", "c", "c", "c", "c", "c",
    "c", "s", "c", "c", "c", "c",
    "c", "c", "s", "c", "c", "c",
    "c", "c", "c", "s", "c", "c",
    "c", "c", "c", "c", "s", "c",
    "c", "c", "c", "c", "c", "s"),
  nrow=6, ncol=6, byrow=TRUE)
dimnames(S5) <- list(rownames(M), rownames(M))
parm5 <- c("s"=10, "c"=2)

S6 <- matrix(
  c("s1", "c1", "c1", NA,  NA,  NA,
    "c1", "s1", "c1",  NA,  NA,  NA,
    "c1", "c1", "s1", NA,  NA,  NA,
    NA,  NA,  NA,  "s2", "c2", "c2",
    NA,  NA,  NA,  "c2", "s2", "c2",
    NA,  NA,  NA,  "c2", "c2","s2"),
  nrow=6, ncol=6, byrow=TRUE)
dimnames(S6) <- list(rownames(M), rownames(M))
parm6 <- c("s1"=12, "c1"=1, "s2"=8, "c2"=2)

sim_fun <- function(n, m, M, S, parm, ...) {
  SigmaK <- EDMAinR:::.vec2mat(parm, EDMAinR:::.mat2fac(S))
  dimnames(SigmaK) <- dimnames(S)
  sim <- edma_simulate_data(n=n, M, SigmaK)
  fit <- edma_fit(sim)
  est <- SigmaK_fit(fit, S, ...)
  s <- sensitivity(est, m)
  structure(
    list(
      n=n,
      m=m,
      M=M,
      S=S,
      parm=parm,
      SigmaK=SigmaK,
      sim=sim,
      fit=fit,
      est=est,
      sensitivity=s
    ),
    class="sim_res"
  )
}

n <- 1000
m <- 200
method <- "Nelder-Mead"

res1 <- sim_fun(n, m, M, S1, parm1, method=method)
res2 <- sim_fun(n, m, M, S2, parm2, method=method)
res3 <- sim_fun(n, m, M, S3, parm3, method=method)
res4 <- sim_fun(n, m, M, S4, parm4, method=method)
res5 <- sim_fun(n, m, M, S5, parm5, method=method)
res6 <- sim_fun(n, m, M, S6, parm6, method=method)


plot.sim_res <- function(res, q=1, main="", hull=TRUE, bias=FALSE) {

  sm <- res$sensitivity
  sm <- sm[order(sm[,"value"]),,drop=FALSE]
  sm <- sm[sm[,"value"] <= quantile(sm[,"value"], q),,drop=FALSE]

  ss <- sm[,-ncol(sm),drop=FALSE]
  colnames(ss) <- gsub("par_", "", colnames(ss))
  ss <- ss[,names(res$parm),drop=FALSE]

  parm <- res$parm
  if (bias) {
#    ss <- t((t(ss) / parm)) - 1
    ss <- t((t(ss) - parm))
    parm[] <- 0
  }

  vv <- sm[,ncol(sm)]

  op <- par(mfrow=c(2,2), mar=c(1,1,1,1))
  on.exit(par(op))

  tmp <- plot_2d(res$sim, which=NULL, ask=NA,
    xlim=c(-100, 100), ylim=c(-60, 60), asp=1, hull=hull)
  xy <- attr(tmp, "coordinates")
  text(xy[,1]+15, xy[,2], labels=rownames(xy), cex=0.6, col=4)
  title(main=main)

  plot_tb(res$S)

  par(mar=c(4,4,1,1))

  boxplot(ss,
    border="darkgrey", col="lightgrey",
    ylab="Value", ylim=range(ss, parm))
  if (ncol(ss) < 2)
    axis(1,at=1,label=colnames(ss))
  if (bias) {
    abline(h=0, col=2)
  } else {
    points(seq_along(res$parm), parm, col=2, pch=3, cex=2)
  }
  points(seq_along(res$parm), ss[1,], col=1, pch=4, cex=2)

  hist(vv,
    border="darkgrey", col="lightgrey",
    main="", xlab="Loss function")

  invisible(res)
}

if (FALSE) {
  save(res1, res2, res3, res4, res5, res6,
       file="~/Dropbox/SigmaK/baboon-data/edma-sim.RData")
  q <- 0.95
  hull <- FALSE
  pdf("~/Dropbox/SigmaK/baboon-data/edma-sim.pdf", onefile=TRUE)
  plot(res1, q, hull=hull)
  plot(res2, q, hull=hull)
  plot(res3, q, hull=hull)
  plot(res4, q, hull=hull)
  plot(res5, q, hull=hull)
  plot(res6, q, hull=hull)
  dev.off()
}


x <- rnorm(100)
y <- rnorm(100) + x*0.8
ell <- dataEllipse(x, y, draw=FALSE, levels=0.95)

plot(x, y)
polygon(cbind(x,y)[chull(cbind(x,y)),], col=NA, border=4)
polygon(.data_ellipse(cbind(x, y)), col=NA, border=2)


