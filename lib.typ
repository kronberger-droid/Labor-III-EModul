#import "@preview/lilaq:0.3.0" as lq

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

#let parse_measurements(path) = {
  let lines = read(path).split("\n").slice(4, -1)
  lines.map(line => {
    let columns = line
      .split("\t")
      .map(x => x.replace(",", ".").trim())
      .filter(x => x != "")
      .map(x => float(x))
    (
      time: columns.at(0),
      voltage: columns.at(1),
    )
  })
}

#let rolling_avg(data, width) = {
  data
    .windows(width)
    .map(seg => {
      (
        time: seg.at(calc.ceil(width / 2)).time,
        voltage: seg.map(entry => entry.voltage).sum() / width,
      )
    })
}

#let remove_outliers_median(data, window_size: 61, threshold_factor: 0.1) = {
  data
    .enumerate()
    .map(((i, point)) => {
      let start = calc.max(0, i - calc.floor(window_size / 2))
      let end = calc.min(data.len(), i + calc.floor(window_size / 2) + 1)
      let local_data = data.slice(start, end)

      // Calculate median and MAD (Median Absolute Deviation)
      let voltages = local_data.map(p => p.voltage)
      let sorted = voltages.sorted()
      let median = sorted.at(calc.floor(sorted.len() / 2))

      let mad = voltages
        .map(v => calc.abs(v - median))
        .sorted()
        .at(calc.floor(voltages.len() / 2))

      // If point is too far from median, replace with median
      if calc.abs(point.voltage - median) > threshold_factor * mad {
        (time: point.time, voltage: median)
      } else {
        point
      }
    })
}

#let signed_derivative(window) = {
  let dt = window.last().time - window.first().time // fixed order
  let dv = window.last().voltage - window.first().voltage
  dv / dt // signed derivative
}

#let classify_points(data, derivative_threshold: 0.01) = {
  let derivatives = data.windows(2).map(x => signed_derivative(x))

  // Classify each point
  let classifications = (
    ("baseline",)
      + derivatives.map(deriv => {
        if deriv > derivative_threshold {
          "rising"
        } else if deriv < -derivative_threshold {
          "falling"
        } else {
          "baseline"
        }
      })
  )

  data
    .zip(classifications)
    .map(((point, classification)) => (
      time: point.time,
      voltage: point.voltage,
      state: classification,
    ))
}

#let segment_by_state(data_with_states) = {
  let segments = ()
  let current_segment = ()
  let current_state = none
  let pulse_mode = false

  for point in data_with_states {
    if point.state != current_state {
      // State change - finish current segment
      if current_segment.len() > 0 {
        let segment_type = if pulse_mode and current_state == "baseline" {
          "pulse"
        } else {
          current_state
        }
        segments.push((state: segment_type, data: current_segment))
        current_segment = ()
      }
      current_state = point.state

      // Update pulse mode based on transitions
      if current_state == "rising" {
        pulse_mode = true
      } else if current_state == "falling" {
        pulse_mode = false
      }
    }
    // Only store time and voltage, not state
    current_segment.push((time: point.time, voltage: point.voltage))
  }

  // Last segment
  if current_segment.len() > 0 {
    let segment_type = if pulse_mode and current_state == "baseline" {
      "pulse"
    } else {
      current_state
    }
    segments.push((state: segment_type, data: current_segment))
  }

  segments
}

#let fit_quadratic(points) = {
  let n = points.len()

  // Calculate sums for matrix system
  let sum_1 = n
  let sum_t = points.map(p => p.time).sum()
  let sum_t2 = points.map(p => p.time * p.time).sum()
  let sum_t3 = points.map(p => calc.pow(p.time, 3)).sum()
  let sum_t4 = points.map(p => calc.pow(p.time, 4)).sum()
  let sum_v = points.map(p => p.voltage).sum()
  let sum_tv = points.map(p => p.time * p.voltage).sum()
  let sum_t2v = points.map(p => p.time * p.time * p.voltage).sum()

  // Solve 3x3 system: [t4 t3 t2][a]   [t2v]
  //                   [t3 t2 t1][b] = [tv ]
  //                   [t2 t1 n ][c]   [v  ]

  // Using Cramer's rule for 3x3 system
  let det = (
    sum_t4 * (sum_t2 * sum_1 - sum_t * sum_t)
      - sum_t3 * (sum_t3 * sum_1 - sum_t * sum_t2)
      + sum_t2 * (sum_t3 * sum_t - sum_t2 * sum_t2)
  )

  let det_a = (
    sum_t2v * (sum_t2 * sum_1 - sum_t * sum_t)
      - sum_tv * (sum_t3 * sum_1 - sum_t * sum_t2)
      + sum_v * (sum_t3 * sum_t - sum_t2 * sum_t2)
  )

  let det_b = (
    sum_t4 * (sum_tv * sum_1 - sum_v * sum_t)
      - sum_t3 * (sum_t2v * sum_1 - sum_v * sum_t2)
      + sum_t2 * (sum_t2v * sum_t - sum_tv * sum_t2)
  )

  let det_c = (
    sum_t4 * (sum_t2 * sum_v - sum_t * sum_tv)
      - sum_t3 * (sum_t3 * sum_v - sum_t * sum_t2v)
      + sum_t2 * (sum_t3 * sum_tv - sum_t2 * sum_t2v)
  )

  (a: det_a / det, b: det_b / det, c: det_c / det)
}

#let correct_segments(seg_data, drift_params) = {
  seg_data.map(segment => (
    state: segment.state,
    data: segment.data.map(point => (
      time: point.time,
      voltage: point.voltage
        - (
          drift_params.a * point.time * point.time
            + drift_params.b * point.time
            + drift_params.c
        ),
    )),
  ))
}

#let correct_segments_linear(seg_data, drift_params) = {
  seg_data.map(segment => (
    state: segment.state,
    data: segment.data.map(point => (
      time: point.time,
      voltage: point.voltage
        - (
          drift_params.at(0) * point.time + drift_params.at(1)
        ),
    )),
  ))
}

#let extract_by_state(seg_data, state) = {
  seg_data.filter(x => x.state == state).map(x => x.data).flatten()
}

#let get_mean_pulse_height(path, avg_window: 7, derivative_threshold: 0.025) = {
  let data = parse_measurements(path)

  let clean_data = remove_outliers_median(data)

  let avg_data = rolling_avg(clean_data, avg_window)

  let segmented_data = segment_by_state(classify_points(
    avg_data,
    derivative_threshold: derivative_threshold,
  ))

  let baseline_data = extract_by_state(segmented_data, "baseline")

  let drift_params = fit_quadratic(baseline_data)

  let corrected_segments = correct_segments(segmented_data, drift_params)

  let segment_means = corrected_segments.map(segment => (
    state: segment.state,
    mean_voltage: segment.data.map(p => p.voltage).sum() / segment.data.len(),
  ))

  let baseline_means = (
    segment_means.filter(s => s.state == "baseline").map(s => s.mean_voltage)
  )
  let pulse_means = (
    segment_means.filter(s => s.state == "pulse").map(s => s.mean_voltage)
  )

  let avg_baseline = baseline_means.sum() / baseline_means.len()
  let avg_pulse = pulse_means.sum() / pulse_means.len()

  let avg_pulse_height = avg_pulse - avg_baseline

  avg_pulse_height
}

#let get_pulse_means(
  path,
  slice_front: 60,
  slice_back: 30,
  rolling_window: 21,
  derivative_threshold: 0.1,
) = {
  let data = parse_measurements(path).slice(slice_front, -slice_back)
  let clean_data = remove_outliers_median(
    data,
    window_size: 21,
    threshold_factor: 0.1,
  )

  let avg_data = rolling_avg(clean_data, 5)

  let segmented_data = segment_by_state(classify_points(avg_data))

  let baseline = extract_by_state(segmented_data, "baseline")
  let drift = linear_fit(baseline.map(x => x.time), baseline.map(y => {
    y.voltage
  }))

  let corrected_segments = correct_segments_linear(segmented_data, drift)

  // Extract only pulse segments and calculate their means
  let pulse_segments = corrected_segments.filter(segment => (
    segment.state == "pulse"
  ))

  pulse_segments.map(segment => {
    segment.data.map(p => p.voltage).sum() / segment.data.len()
  })
}

#let area_circle_strip(diameter, strip_height) = {
  let radius = diameter / 2
  let circle_area = calc.pi * radius * radius

  // Safety check
  if strip_height >= diameter {
    return circle_area
  }

  // Height of each cap that gets removed
  let cap_height = (diameter - strip_height) / 2

  // For a circular segment with height h:
  let r_minus_h = radius - cap_height
  let angle_rad = calc.acos(r_minus_h / radius) / 1rad
  let triangle_base = calc.sqrt(
    2 * radius * cap_height - cap_height * cap_height,
  )
  let segment_area = radius * radius * angle_rad - r_minus_h * triangle_base

  // Remove two segments (top and bottom)
  circle_area - 2 * segment_area
}

#let process_single_dataset(dataset, masses) = {
  let pulse_means = get_pulse_means(
    dataset.path,
    slice_front: dataset.slice_front,
    slice_back: dataset.slice_back,
    rolling_window: dataset.rolling_window,
    derivative_threshold: dataset.derivative_threshold,
  )

  // Convert masses to forces (F = mg, with g ≈ 9.81 m/s²)
  let forces = masses.map(m => m * 9.81)

  // Return processed data
  (
    voltage: dataset.voltage,
    path: dataset.path,
    forces: forces,
    deflections: pulse_means,
    num_pulses: pulse_means.len(),
  )
}

// Process all datasets
#let process_all_datasets(datasets, masses_list) = {
  datasets
    .enumerate()
    .map(((i, dataset)) => {
      process_single_dataset(dataset, masses_list)
    })
}

// Plot multiple datasets on same graph
#let plot_multiple_datasets(
  processed_datasets,
  title: "Force vs Deflection Comparison",
) = {
  let colors = (blue, red, green, orange)

  lq.diagram(
    width: 14cm,
    height: 10cm,
    ..processed_datasets
      .enumerate()
      .map(((i, dataset)) => {
        let color = colors.at(calc.rem(i, colors.len()))
        lq.plot(
          mark: "o",
          dataset.deflections,
          dataset.forces,
          stroke: none,
          label: str(dataset.voltage) + "V",
        )
      }),
    xlabel: "Deflection w (V)",
    ylabel: "Force F (N)",
    title: title,
  )
}
