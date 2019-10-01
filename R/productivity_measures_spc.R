productivity.measures.spc <- function (obj, measures, ...)
{
  supported <- qw("K D R S H C P TTR Hapax V")
  if (missing(measures)) measures <- supported
  measures <- sapply(measures, match.arg, choices=supported)
  res <- numeric(length(measures))

  m.max <- attr(obj, "m.max") # if m.max > 0, spectrum is incomplete
  if (m.max == 0) m.max <- Inf

  ## check which measures can be computed from the available spectrum
  idx.ok <- (
    (measures %in% qw("R C V TTR")) | 
    (measures %in% qw("H P Hapax") & m.max >= 1) | 
    (measures %in% qw("S") & m.max >= 2) | 
    (m.max == Inf))
  res <- numeric(length(measures))
  res[!idx.ok] <- NA

  ## now compute all selected productivity measures
  res[idx.ok] <- sapply(measures[idx.ok], function (M.) {
    switch(M.,
           ## measures based on single spectrum element: expectations are exact
           R = V(obj) / sqrt(N(obj)),
           C = log( V(obj) ) / log( N(obj) ),
           P = Vm(obj, 1) / N(obj),
           TTR = V(obj) / N(obj),
           V = V(obj),
           ## measures based on two spectrum elements: expectations based on
           ## rough normal approximation of the distribution of Vm / V
           ##  - assumption: Vm and (V - Vm) are independent (not actually true)
           ##  - then Vm / (Vm + (V - Vm)) is roughly normal (Evert 2004b, Lemma A.8, p. 179)
           ##  - with E[Vm / V] = E[Vm] / E[V]
           ##  - H also assumes that the transformation 1 / (1 - Vm / V) doesn't skew the distribution
           S = Vm(obj, 2) / V(obj),
           H = 100 * log( N(obj) ) / (1 - Vm(obj, 1) / V(obj)),
           Hapax = Vm(obj, 1) / V(obj),
           ## Yule K and Simpson D can only be computed from full spectrum
           K = {
             m <- as.numeric(obj$m)
             Vm <- as.numeric(obj$Vm)
             10e3 * (sum(m * m * Vm) - N(obj)) / (N(obj) ^ 2)
           },
           D = {
             m <- as.numeric(obj$m)
             Vm <- as.numeric(obj$Vm)
             sum(Vm * (m / N(obj)) * ((m - 1) / (N(obj) - 1)))
           })
  })

  names(res) <- measures
  res
}