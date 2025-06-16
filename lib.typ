#let linear_fit(xs, ys) = {
  let n = xs.len()
  let Sx = xs.sum()
  let Sy = ys.sum()
  let Sxx = xs.map(x => x * x).sum()
  let Sxy = xs.zip(ys).map(p => p.product()).sum()
  let Syy = ys.map(y => y * y).sum()

  // slope & intercept
  let m = (n * Sxy - Sx * Sy) / (n * Sxx - Sx * Sx)
  let c = (Sy - m * Sx) / n

  // residual sum of squares
  let SSR = Syy - m * Sxy - c * Sy

  // variance of x
  let Sxx_bar = Sxx - (Sx * Sx) / n

  // 1σ error on slope
  let sigma_m = calc.sqrt((SSR / (n - 2) / Sxx_bar))

  (m, c, sigma_m)
}

#let fit_through_origin(xs, ys) = {
  assert(xs.len() == ys.len())
  let sxy = xs.zip(ys).map(p => p.product()).sum()
  let sx2 = xs.map(x => x * x).sum()
  sxy / sx2
}

#let fit_through_origin(xs, ys) = {
  assert(xs.len() == ys.len())
  let sxy = xs.zip(ys).map(p => p.product()).sum()
  let sx2 = xs.map(x => x * x).sum()
  sxy / sx2
}
