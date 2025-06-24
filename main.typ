#import "lab-report.typ": lab-report
#import "@preview/lilaq:0.3.0" as lq
#import calc: ln, round
#import "lib.typ": linear_fit

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

#let data = parse_measurements("data/1/2KG2_5VAlu.data")

=== example diagram

#let split_baseline_pulse(data, derivative_threshold: 0.01) = {
  let derivatives = range(data.len() - 1).map(i => {
    let dt = data.at(i + 1).time - data.at(i).time
    let dv = data.at(i + 1).voltage - data.at(i).voltage
    calc.abs(dv / dt) // absolute derivative
  })

  // Classify points (first point is baseline by default)
  let classifications = (
    (true,) + derivatives.map(deriv => deriv < derivative_threshold)
  )

  data.zip(classifications)
}

#let split_data = split_baseline_pulse(data, derivative_threshold: 0.1)

#lq.diagram(
  width: 12cm,
  height: 8cm,
  xlabel: [time t in s],
  ylabel: [voltage U in V],
  lq.plot(mark: none, data.map(x => x.time), data.map(x => {
    x.voltage
  })),
  lq.plot(mark: none, split_data.map(x => x.first().time), split_data.map(x => {
    if x.last() == true { 1 } else { 0 }
  })),
)

== Data Analysis

1. Calculate cross-sectional area: $A = pi/4 (D^2 - d^2)$
2. Calculate stress: $sigma = F/A$
3. Calculate strain from voltage readings: $epsilon = U/(k dot U_"bridge")$
4. Plot stress vs. strain for each material
5. Determine $E$ from the slope of the linear region
6. Perform error propagation analysis considering individual measurement uncertainties
7. Compare experimental values with literature values


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
