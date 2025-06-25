#import "lab-report.typ": lab-report
#import "@preview/lilaq:0.3.0" as lq
#import calc: ln, round
#import "lib.typ": *
#import "datasets.typ": *

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

$ E = (sigma)/(epsilon) = (F/A)/((Delta L) / L_0) = (F/A)/((2U_0)/(Delta U)) $

where F is the applied force, A is the cross-sectional area, $Delta L$ is the elongation, and $L_0$ is the original length. The measurement uses strain gauges with a bridge circuit configuration.

== Setup
#grid(
  columns: 2,
  column-gutter: 0.4cm,
  align: center + bottom,
  [
    #figure(
      image("assets/setup_1.png"),
      caption: [Measurement Setup. #cite(<DMS-EModul>)],
    )
  ],
  [
    #figure(
      image(width: 3cm, "assets/profile.png"),
      caption: [Geometry of the Tension Rods. #cite(<DMS-EModul>)],
    )
  ],
)
#grid(
  columns: 2,
  column-gutter: 1cm,
  [
    *Equipment:*
    - Bridge extension device
    - Tension rods (Aluminum, Steel, Brass, Plexiglas)
    - Strain gauge measurement system
    - Calibrated weights
    - Digital multimeter
    *K-factor:* $k=2.03 plus.minus 1%$ (pre-calibrated)
  ],
  [
    *Material Specifications:*
    #figure(caption: [Geomteric material specifications], table(
      columns: 3,
      align: center,
      table.header([Material], [Durchmesser D[mm]], [Breite d[mm]]),
      [Aluminium], [14.85], [3.7],
      [Steel], [14.85], [3.7],
      [Brass], [14.85], [3.7],
      [Plexiglas], [14.85], [3.7],
    ))
  ],
)


== Procedure

+ Switch the bridge extension device to 1/2 position
+ Connect the first tension rod to the bridge extension
+ Wait 5 minutes for thermal equilibration
+ Bridge Adjustment:
  - Set the bridge voltage to 5V using switch S5. Turn A1 to "ON" and set A2 to 1. Ensure the calibration switch S6 is at 0, and set the filter S7 to 10 Hz. Set S4 to full bridge and leave it in this position for the entire experiment.
  - Next, adjust the measurement range with S3 until instrument M1 no longer shows full-scale deflection. Then perform a zero adjustment using S1, S2, and P1, gradually switching back to the most sensitive range via S3.
  - The capacitance is balanced by adjusting P2 until the reading on instrument M2 shows a minimum value.
+ Bridge Calibration:
  - Set S3 to the most sensitive range (0.05). The zero point should remain unchanged (thermal equilibrium); otherwise, correct with P3.
  - Set calibration switch S6 to +0.05. Instrument M1 should now show full-scale deflection (100), and the digital voltmeter should read exactly 10V (±0.05V). If not, fine-tune with P3.
  - For verification, reduce the bridge voltage to 2.5V. The pointer on M1 should indicate 50. Finally, return S6 to 0.
+ For each material, perform 4 measurement series:
  - Series with 5V and 2.5V excitation voltage, and
  - Series with 2 kg and 5 kg loading
+ Take 5 measurements per series
+ Record all voltage readings and corresponding loads
+ Repeat for all four materials

== Measurement values

#let path = "data/1/2KG2_5VAlu.data"
#let window_width = 11
#let threshold = 0.01

#let data = parse_measurements(path)

#let clean_data = remove_outliers_median(
  data,
  window_size: 11,
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
    xlabel: [Time t in s],
    ylabel: [Voltage U in V],
    ylim: (-0.1, 1.8),
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
      label: [Cleaned data],
      mark: none,
      clean_data.map(x => x.time),
      clean_data.map(x => {
        x.voltage
      }),
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

1. Calculate cross-sectional area: $A = D^2 (​arccos(d/D​)−d/D sqrt(1−(d/D​)^2))​$
2. Calculate stress: $sigma = F/A$
3. Calculate strain from voltage readings: $epsilon = U_0/(k dot U_b)$, but since the k-factor is already accounted for in the calibration , but since the k-factor is already accounted for in the calibration $epsilon = U_0/(U_b)$ is used.
/*$
x_m = 1/n sum_{i=1}^{n} x_i
$*/
4. Plot stress vs. strain for each material
5. Determine EE from the slope of the linear region
6. Perform error propagation analysis considering individual measurement uncertainties (weight, cross-section, measurement, drift)-> but no data to it...so only mean deviation?
A calibration error with this setup can be approximated to $plus.minus$0,1V with the measuring Voltage of 2,5V and 5V. Therefore the relative error is 0,04%.
/*
$
s = sqrt( 1/(n - 1) sum_{i=1}^n (x_i - x_m)^2 )
$
*/
7. Compare experimental values with literature values
  - Aluminum: E = 70 GPa
  - Steel: E = 210 GPa
  - Brass: E = 78-123 GPa
  - Plexiglas: E = 3 GPa

#let material_properties = (
  "Alu": (
    D: 14.85e-3, // outer diameter in meters
    d: 3.7e-3, // inner diameter in meters
    area: area_circle_strip(14.85e-3, 3.7e-3),
  ),
  "Stahl": (
    D: 15e-3,
    d: 2.2e-3,
    area: area_circle_strip(15e-3, 2.2e-3),
  ),
  "Messing": (
    D: 15.8e-3,
    d: 3e-3,
    area: area_circle_strip(15.8e-3, 3e-3),
  ),
  "Glas": (
    // Plexiglas
    D: 15.2e-3,
    d: 7.7e-3,
    area: area_circle_strip(15.2e-3, 7.7e-3),
  ),
)

#let calculate_strain(pulse_height_volts, bridge_voltage) = {
  let voltage_ratio = (2 * bridge_voltage) / (pulse_height_volts * 5e-5)
  let k_factor = 2.03
  (
    1 / voltage_ratio
  )
}

// Calculate results with strain and elasticity modulus
#let results = datasets_1.map(dataset => {
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

#figure(caption: [], table(
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
      str(calc.round(r.elasticity_modulus / 1e9, digits: 5)), // GPa
    ))
    .flatten(),
))

== Error Analysis
A calibration error with this setup can be approximated to $plus.minus 0.1 "V"$ with the measuring Voltage of 2.5V and 5V. Therrefore the relative error is 0.04%.

#pagebreak()

= Bending Beam Analysis

== Fundamentals

The strain gauge measures strain ε at the surface of the beam:

$
  epsilon = sigma/E = (M dot h/2)/(I dot E)
$

Where the bending moment M at distance x from the free end:
$
  M = F dot (L - x)
$

Therefore:
$
  epsilon = (F dot (L - x) dot h/2)/(I dot E)
$

The strain gauge output voltage is proportional to strain:
$
  U_A = gamma dot epsilon = gamma dot (F dot (L-x) dot h/2)/(I dot E)
$

Solving for the weight G = F/g:
$
  G = (2 dot I dot E dot U_A)/(gamma dot g dot (L-x) dot h)
$

== Setup

#figure(
  image(width: 10cm, "assets/setup_2.png"),
  caption: [Cantilever beam setup. #cite(<DMS-EModul>)],
)


*Equipment:*
- Cantilever beam setup
- Strain gauge measurement system
- Calibrated weights (2g, 5g, 10g, 20g, 50g, 100g, 200g, 500g)
- Two unknown weights
- Ruler for length measurements
- Caliper for cross-section measurements

/**Beam Configuration:*
- Length LL to be measured
- Cross-section dimensions to be determined
- Support conditions: fixed-free (cantilever)*/

== Procedure

+ Set the bridge extension device to 1/4 bridge configuration.
+ Connect the bending beam to the bridge extension device and wait at least 5 minutes before proceeding.
+ Measure the dimensions of the bending beam using a caliper: length (15,55$plus.minus$0,25 mm), width (2,05$plus.minus$0,05 mm), and height (5$plus.minus$0,05 mm).
+ Check and, if necessary, adjust the zero point and calibration:
  - Zero point: adjust using P1 and P2
  - Calibration: adjust using P3
+ Perform measurements at both 5V and 2.5V bridge voltage.
+ Determine the bridge output voltage ($U_A$) for different masses (weights), starting from 500g downward until no significant difference can be measured.
== Measurement Values

#let data = parse_measurements("data/2/bekannte_gewichte_2_5V.data").slice(
  60,
  -80,
)

#let clean_data = remove_outliers_median(
  data,
  window_size: 21,
  threshold_factor: 0.1,
)

#let avg_data = rolling_avg(clean_data, 5)

#let classified_points = classify_points(avg_data)
#let segmented_data = segment_by_state(classified_points)

#let baseline = extract_by_state(segmented_data, "baseline")

#let drift = linear_fit(baseline.map(x => x.time), baseline.map(y => y.voltage))

#let corrected_segmented_data = correct_segments_linear(segmented_data, drift)

#let baseline = extract_by_state(corrected_segmented_data, "baseline")

#let pulses = corrected_segmented_data.filter(x => x.state == "pulse")
#let pulse = extract_by_state(corrected_segmented_data, "pulse")

#let pulse_means = get_pulse_means("data/2/bekannte_gewichte_5V.data")


#figure(
  caption: [
    After applying a rolling average onto the raw data, it is segmented into baseline, pulses, rising and falling slopes.
    Afterwards a quadratic function is fitted onto the baseline dataset and subtracted from the segmented dataset.
    This results in clear baseline and pulse datasets which can be averaged over.
  ],
  lq.diagram(
    title: [Illustration of data preparation Aluminium at 2.5 V],
    width: 12cm,
    height: 8cm,
    xlabel: [Time t in s],
    ylabel: [Voltage U in V],
    lq.plot(mark: none, clean_data.map(x => x.time), clean_data.map(y => {
      y.voltage
    })),
    lq.plot(stroke: none, pulse.map(x => x.time), pulse.map(y => {
      y.voltage
    })),
    lq.plot(stroke: none, baseline.map(x => x.time), baseline.map(y => {
      y.voltage
    })),
  ),
)

#let data_sets = process_all_datasets(datasets_2, masses)

#let known_weight_datasets = data_sets.filter(x => x.num_pulses == 7)

#let fit_1 = linear_fit(
  known_weight_datasets.first().forces,
  known_weight_datasets.first().deflections,
)

#let fit_2 = linear_fit(
  known_weight_datasets.last().forces,
  known_weight_datasets.last().deflections,
)

#figure(lq.diagram(
  width: 12cm,
  height: 8cm,
  xlabel: [Deflection $omega$ in m],
  ylabel: [Force $F$ in N],
  legend: (position: left + top),
  lq.plot(
    stroke: none,
    mark-size: 6pt,
    color: olive,
    label: [2.5 V],
    known_weight_datasets.first().forces,
    known_weight_datasets.first().deflections,
  ),
  lq.plot(
    mark: none,
    label: [$F = #round(fit_1.at(0), digits: 2) dot omega$],
    color: olive,
    lq.linspace(0.0, 5.0),
    lq.linspace(0.0, 5.0).map(x => fit_1.at(0) * x + fit_1.at(1)),
  ),
  lq.plot(
    stroke: none,
    color: maroon,
    mark-size: 6pt,
    label: [5 V],
    known_weight_datasets.last().forces,
    known_weight_datasets.last().deflections,
  ),
  lq.plot(
    mark: none,
    label: [$F = #round(fit_2.at(0), digits: 2) dot omega$],
    color: maroon,
    lq.linspace(0.0, 5.0),
    lq.linspace(0.0, 5.0).map(x => fit_2.at(0) * x + fit_2.at(1)),
  ),
))

*Beam Geometry:*
- Length L = 15.55$plus.minus$0,25 mm
- Width b = 2.05$plus.minus$0,05 mm
- Height h = 5$plus.minus$0,05 mm
- Point of attack x = 13.5$plus.minus$0,25 mm
- Second moment of area $I = (b h^3)/12 =I = (b h^3)/12$

// Beam geometry parameters
#let L = 15.55e-3  // Length in m
#let b = 2.05e-3   // Width in m
#let h = 5e-3      // Height in m
#let x = 13.5e-3   // Point of attack in m
#let g = 9.81      // Gravity in m/s²

// Second moment of area
#let I = (b * calc.pow(h, 3)) / 12

// Calculate sensitivity values
#let gamma_1 = {
  let slope = fit_1.at(0) // N/V
  let sensitivity = (2 * I * 70e9) / (g * (L - x) * h) // Assuming E ≈ 70 GPa
  sensitivity / slope
}

#let gamma_2 = {
  let slope = fit_2.at(0) // N/V
  let sensitivity = (2 * I * 70e9) / (g * (L - x) * h)
  sensitivity / slope
}

#figure(caption: [Values for known weights], table(
  columns: (auto, auto, auto, auto),
  align: center,
  [*Parameter*], [*2.5V Dataset*], [*5V Dataset*], [*Units*],

  [Slope k],
  [#calc.round(fit_1.at(0), digits: 3)],
  [#calc.round(fit_2.at(0), digits: 3)],
  [N/V],

  [Intercept],
  [#calc.round(fit_1.at(1), digits: 4)],
  [#calc.round(fit_2.at(1), digits: 4)],
  [N],

  [Sensitivity γ],
  [#calc.round(gamma_1, digits: 6)],
  [#calc.round(gamma_2, digits: 6)],
  [V·m⁻¹],

  [Effective length (L-x)],
  [#calc.round((L - x) * 1000, digits: 2)],
  [#calc.round((L - x) * 1000, digits: 2)],
  [mm],

  [Second moment I],
  [#calc.round(I * 1e12, digits: 3)],
  [#calc.round(I * 1e12, digits: 3)],
  [mm⁴],
))

== Unknown Weight Determination

#let unknown_weight_datasets = data_sets.filter(x => x.num_pulses != 7)

Using the 5V calibration curve: $F = #calc.round(fit_2.at(0), digits: 2) dot U_A #calc.round(fit_2.at(1), digits: 4)$

#if unknown_weight_datasets.len() > 0 [
  #figure(caption: [Values for unknown weights], table(
    columns: (auto, auto, auto, auto),
    align: center,
    [*Voltage*],
    [*Deflection (V)*],
    [*Predicted Force (N)*],
    [*Predicted Mass (g)*],

    // Process each unknown dataset
    ..unknown_weight_datasets
      .map(dataset => {
        let predicted_forces = dataset.deflections.map(deflection => {
          fit_2.at(0) * deflection + fit_2.at(1)
        })
        let predicted_masses = predicted_forces.map(force => (
          force / g * 1000
        )) // Convert to grams

        // Create table rows for this dataset
        dataset
          .deflections
          .enumerate()
          .map(((i, deflection)) => (
            if i == 0 { str(dataset.voltage) + "V" } else { "" },
            str(calc.round(deflection, digits: 4)),
            str(calc.round(predicted_forces.at(i), digits: 3)),
            str(calc.round(predicted_masses.at(i), digits: 1)),
          ))
      })
      .flatten(),
  ))
] else [
  No unknown weight datasets found.
]

== Strain Verification: $epsilon prop h/2$

From beam theory, the maximum strain occurs at the surface (distance h/2 from neutral axis):

$
  epsilon_"max" = (M dot h/2)/I = (F dot (L-x) dot h/2)/I
$

For your beam geometry:
- $h/2 = #calc.round(h / 2 * 1000, digits: 2) "mm"$
- $I = #calc.round(I * 1e12, digits: 3) "mm"^4$
- $"Effective length" (L-x) = #calc.round((L - x) * 1000, digits: 2) "mm"$

The strain is directly proportional to h/2, confirming the theoretical relationship.

== Sensitivity Analysis

The relationship $G = gamma dot U_A$ yields:

- 2.5V sensitivity: $gamma = #calc.round(gamma_1, digits: 6) "Vm"^(-1)$
- 5V sensitivity: $gamma = #calc.round(gamma_2, digits: 6) "Vm"^(-1)$

The ratio of sensitivities is #calc.round(gamma_2 / gamma_1, digits: 2), which should be close to 2.0 if the system is linear.

== Error Sources

1. *Geometric tolerances*: ±0.25 mm on length, ±0.05 mm on height
2. *Loading position uncertainty*: ±0.25 mm affects moment arm
3. *Strain gauge placement*: Must be at maximum strain location
4. *Temperature effects*: Affects E-modulus and gauge sensitivity
5. *Linearity assumption*: Valid only for small deflections

#pagebreak()

#outline(title: [List of Tables], target: figure.where(kind: table))
#outline(title: [List of Figures], target: figure.where(kind: image))

#bibliography("bib.yaml")
