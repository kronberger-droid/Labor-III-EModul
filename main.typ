#import "lab-report.typ": lab-report
#import "@preview/lilaq:0.3.0" as lq
#import calc: ln, round
#import "lib.typ": *
#import "datasets.typ": datasets

#show: lab-report.with(
  title: "Elasticity Modulus",
  authors: ("Raul Wagner", "Martin Kronberger"),
  supervisor: "",
  groupnumber: "301",
  date: datetime(day: 18, month: 6, year: 2025),
)

#outline()

#pagebreak()

= Elasticity Modulus of Tension Rods

== Fundamentals

The elasticity modulus (Young's modulus) $E$ describes the relationship between stress and strain in the elastic deformation region. For a tension rod under axial load:

$ E = (sigma)/(epsilon) = (F/A)/(Delta L / L_0) $

where $F$ is the applied force, $A$ is the cross-sectional area, $Delta L$ is the elongation, and $L_0$ is the original length. The measurement uses strain gauges with a bridge circuit configuration.

== Setup

*Equipment:*
- Bridge extension device
- Tension rods (Aluminum, Steel, Brass, Plexiglas)
- Strain gauge measurement system
- Calibrated weights or voltage source
- Digital multimeter

*Material Specifications:*
- Aluminum: $D = 14.85$ mm, $d = 3.7$ mm
- Steel: $D = 15$ mm, $d = 2.2$ mm
- Brass: $D = 15.8$ mm, $d = 3$ mm
- Plexiglas: $D = 15.2$ mm, $d = 7.7$ mm

*K-factor:* $k = 2.03 ± 1%$ (pre-calibrated)

== Procedure

1. Switch the bridge extension device to 1/2 position
2. Connect the first tension rod to the bridge extension
3. Wait 5 minutes for thermal equilibration
4. For each material, perform 4 measurement series:
  - Series with 5V and 2.5V excitation voltage, OR
  - Series with 2 kg and 5 kg loading
5. Take at least 6 measurements per series
6. Record all voltage readings and corresponding loads
7. Repeat for all four materials

== Measurement Values

#let path = "data/1/2KG5VStahl.data"
#let window_width = 15
#let threshold = 0.12

#let data = parse_measurements(path)

#let clean_data = remove_outliers_median(
  data,
  window_size: 12,
  threshold_factor: 0.1,
)

#let avg_data = rolling_avg(clean_data, window_width)

#let split_data = segment_by_state(classify_points(
  avg_data,
  derivative_threshold: threshold,
))

#let drift_params = fit_quadratic(extract_by_state(split_data, "baseline"))

#let corrected_segments = correct_segments(split_data, drift_params)

#let segment_means = corrected_segments.map(segment => (
  state: segment.state,
  mean_voltage: segment.data.map(p => p.voltage).sum() / segment.data.len(),
))

#let baseline_points = extract_by_state(corrected_segments, "baseline")

#let pulse_points = extract_by_state(corrected_segments, "pulse")

#let avg_pulse_height = get_mean_pulse_height(path)

#figure(
  caption: [
    After applying a rolling average onto the raw data, it is segmented into baseline, pulses, rising and falling slopes.
    Afterwards a quadratic function is fitted onto the baseline dataset and subtracted from the segmented dataset.
    This results in clear baseline and pulse datasets which can be averaged over.
  ],
  lq.diagram(
    title: [Illustration of data preparation for 2 Kg Aluminium at 2.5 V],
    width: 12cm,
    height: 8cm,
    xlabel: [time t in s],
    ylabel: [voltage U in V],
    // ylim: (-0.1, 1.8),
    legend: (position: top + left),
    lq.plot(
      label: [Raw data],
      mark: none,
      data.map(x => x.time),
      data.map(x => {
        x.voltage
      }),
    ),
    lq.plot(
      label: [Averaged data],
      mark: none,
      clean_data.map(x => x.time),
      clean_data.map(x => {
        x.voltage
      }),
    ),
    lq.line(
      label: [Average pulse height: $Delta U_"avg" = #round(avg_pulse_height, digits: 2)$],
      stroke: (dash: (2pt, 1pt)),
      (0, avg_pulse_height),
      (120, avg_pulse_height),
    ),
    lq.plot(
      label: [Baseline segments],
      stroke: none,
      baseline_points.map(x => x.time),
      baseline_points.map(p => {
        p.voltage
      }),
    ),
    lq.plot(
      label: [Pulse segments],
      stroke: none,
      pulse_points.map(x => x.time),
      pulse_points.map(p => {
        p.voltage
      }),
    ),
  ),
)

== Data Analysis

1. Calculate cross-sectional area: $A = pi/4 (D^2 - d^2)$
2. Calculate stress: $sigma = F/A$
3. Calculate strain from voltage readings: $epsilon = U/(k dot U_"bridge")$
4. Plot stress vs. strain for each material
5. Determine $E$ from the slope of the linear region
6. Perform error propagation analysis considering individual measurement uncertainties
7. Compare experimental values with literature values

#let material_properties = (
  "Alu": (
    D: 14.85e-3, // outer diameter in meters
    d: 3.7e-3, // inner diameter in meters
    area: calc.pi / 4 * (calc.pow(14.85e-3, 2) - calc.pow(3.7e-3, 2)),
  ),
  "Stahl": (
    D: 15e-3,
    d: 2.2e-3,
    area: calc.pi / 4 * (calc.pow(15e-3, 2) - calc.pow(2.2e-3, 2)),
  ),
  "Messing": (
    D: 15.8e-3,
    d: 3e-3,
    area: calc.pi / 4 * (calc.pow(15.8e-3, 2) - calc.pow(3e-3, 2)),
  ),
  "Glas": (
    // Plexiglas
    D: 15.2e-3,
    d: 7.7e-3,
    area: calc.pi / 4 * (calc.pow(15.2e-3, 2) - calc.pow(7.7e-3, 2)),
  ),
)

#let calculate_strain(pulse_height_volts, bridge_voltage) = {
  let voltage_ratio = pulse_height_volts / bridge_voltage
  let k_factor = 2.03
  voltage_ratio * 2 / k_factor
}

// Calculate results with strain and elasticity modulus
#let results = datasets.map(dataset => {
  let pulse_height = get_mean_pulse_height(dataset.path)
  let strain = calculate_strain(pulse_height, dataset.voltage)
  let material_props = material_properties.at(dataset.material)
  let stress = (dataset.weight * 9.81) / material_props.area // Pa
  let elasticity_modulus = stress / strain // Pa

  (
    ..dataset,
    pulse_height: pulse_height,
    strain: strain,
    stress: stress,
    elasticity_modulus: elasticity_modulus,
    cross_area: material_props.area,
  )
})

#table(
  columns: 7,
  align: center,
  [Weight (kg)],
  [Voltage (V)],
  [Material],
  [Pulse Height (V)],
  [Strain],
  [Stress (MPa)],
  [E-Modulus (GPa)],
  ..results
    .map(r => (
      str(r.weight),
      str(r.voltage),
      r.material,
      str(calc.round(r.pulse_height, digits: 4)),
      str(calc.round(r.strain * 1e6, digits: 1)), // microstrains
      str(calc.round(r.stress / 1e6, digits: 2)), // MPa
      str(calc.round(r.elasticity_modulus / 1e9, digits: 2)), // GPa
    ))
    .flatten(),
)

= Bending Beam Analysis

== Fundamentals

For a cantilever beam under point load, the deflection $w$ is related to the applied force $F$ by:

$ w = (F L^3)/(3 E I) $

where $L$ is the beam length, $E$ is the elasticity modulus, and $I$ is the second moment of area. The relationship between bending moment and curvature is:

$ M = E I kappa $

== Setup

*Equipment:*
- Cantilever beam setup
- Displacement measurement system (dial gauge or LVDT)
- Calibrated weights
- Ruler for length measurements
- Caliper for cross-section measurements

*Beam Configuration:*
- Length $L$ to be measured
- Cross-section dimensions to be determined
- Support conditions: fixed-free (cantilever)

== Procedure

1. Set up the cantilever beam with proper clamping
2. Ensure the beam is horizontal using a level
3. Position the displacement measurement device at the free end
4. Apply loads incrementally (suggested: 0.5, 1.0, 1.5, 2.0 kg)
5. Wait for stabilization between each load increment
6. Record deflection for each load
7. Repeat measurements 3 times for statistical analysis
8. Unload and check for permanent deformation

== Measurement Values

*Data Collection:*
#table(
  columns: 5,
  [Load F (N)], [Deflection w (mm)], [Trial 1], [Trial 2], [Trial 3],
  [0], [0], [], [], [],
  [4.9], [], [], [], [],
  [9.8], [], [], [], [],
  [14.7], [], [], [], [],
  [19.6], [], [], [], [],
)

*Beam Geometry:*
- Length $L =$ mm
- Width $b =$ mm
- Height $h =$ mm
- Second moment of area $I = (b h^3)/12 =$ mm⁴

== Data Analysis

1. Plot load $F$ vs. deflection $w$
2. Determine the slope $k = (Delta F)/(Delta w)$
3. Calculate theoretical deflection: $w_"theory" = (F L^3)/(3 E I)$
4. Compare experimental slope with theoretical prediction
5. Calculate experimental elasticity modulus: $E_"exp" = (F L^3)/(3 I w)$
6. Analyze linearity and determine measurement uncertainty
7. Calculate percentage error compared to known material properties
8. Discuss sources of experimental error (beam self-weight, clamping effects, measurement precision)

*Error Analysis:*
- Systematic errors: calibration, geometric measurements
- Random errors: measurement repeatability, environmental factors
- Propagation of uncertainties through calculations

*Expected Results:*
Compare experimental values with typical elasticity moduli for common materials (Steel: ~200 GPa, Aluminum: ~70 GPa).

#pagebreak()

#outline(title: [List of Tables], target: figure.where(kind: table))
#outline(title: [List of Figures], target: figure.where(kind: image))

#bibliography("bib.yaml")
