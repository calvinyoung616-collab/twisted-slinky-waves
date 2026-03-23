# Twisted Slinky Waves

![Twisted slinky system](figures/slinky.jpg)

This repository contains research and teaching materials for studying the wave dynamics of a twisted slinky. The project focuses on the motion that arises when a slinky is twisted and released while its bottom end is fixed.

In this configuration, a torsional disturbance propagates along the slinky and reflects at the boundaries, producing a characteristic periodic motion. At the same time, the system exhibits transverse motion, leading to directly observable coupled torsional and transverse dynamics.

The phenomenon provides a simple and visually clear demonstration of wave propagation, boundary conditions, and coupled motion in mechanical systems.

This repository is intended to support both **research reproducibility** and **educational use**.

---

## Physical system

The experiments use a commercial **plastic slinky toy**. Plastic slinkies are recommended because they reproduce the target phenomena more reliably than steel springs.

In preliminary tests with steel springs, two main difficulties were observed:

- For large initial twists, the transverse motion becomes large and the spring tends to collapse.
- For small twists, the transverse oscillation is weak and difficult to observe clearly.

In practice, steel springs are therefore more difficult to use for a clean reproduction of the phenomena studied here. A possible reason is that, for the material parameters of the steel springs we tested, the shear response is less effective in stabilizing the rotational motion of the coils. As a result, the transverse displacement can grow rapidly.

This effect can also be explored numerically by modifying the material parameters in the MATLAB scripts.

---

## Repository structure

The repository is organized into the following directories:

- `code/`  
  MATLAB scripts for theoretical modeling and numerical simulations.

- `data/`  
  Experimental data extracted from video analysis.

- `figures/`  
  Figures used in the paper and repository documentation.

- `tracker/`  
  Tracker project files used for motion tracking and data extraction.

- `teaching/`  
  Teaching notes, experimental guidance, and suggested activities.

- `videos/`  
  Example recordings of torsional and transverse motion.

- `README.md`  
  Overview of the repository and instructions for use.

The example videos included in this repository were recorded using **Spring No. 2** listed in the parameter table of the paper. Other springs with different parameters were also tested in the experiments, but Spring No. 2 is used here as a representative example.

---

## Experimental setup

![Experimental setup](figures/setup.png)

The experiment uses a plastic slinky whose bottom end is fixed to a horizontal surface. The top of the slinky is twisted through several turns and then released.

The motion is recorded using a high-speed camera (Metalab+ 300C-U3) at **300 fps**. A reflective marker is attached near the top point to facilitate motion tracking.

In general:

- top-view recordings are mainly used for torsional-wave measurements;
- side-view recordings are mainly used for transverse-wave measurements.

The recorded videos are analyzed using **Tracker (version 6.3.x)** to obtain time-series data of the motion.

The experimental data provided in this repository are stored in:

`data/experiment data.xlsx`

---

## Data analysis

The motion of selected points on the slinky is extracted using Tracker. The resulting position and velocity data are used to determine the oscillation periods of the observed waves.

More specifically:

- the period of the torsional wave is estimated from the motion of the top point;
- the period of the transverse wave is estimated from side-view tracking at a selected height;
- fast Fourier transform (**FFT**) is used as an auxiliary method for estimating the oscillation frequency of the transverse motion.

---

## Numerical modeling

The `code/` directory contains MATLAB scripts used to model the dynamics of the system.

### `torsional_wave_model.m`

This script solves the torsional-wave equation and visualizes the angular motion of the slinky. It generates:

- angular displacement as a function of position and time;
- angular velocity distributions;
- three-dimensional visualizations of the wave evolution.

### `transverse_wave_simulation.m`

This script solves the equation governing the transverse motion of the coil centers. It produces:

- two-dimensional trajectories of the top coil;
- displacement-time curves;
- velocity-time curves;
- oscillation period estimates using FFT.

The simulations were developed and tested using **MATLAB R2024a**.

---

## Teaching resources

The system can be used as a classroom demonstration or as part of an undergraduate laboratory experiment on wave motion.

Possible student activities include:

- measuring the period of the torsional wave;
- verifying that the torsional-wave period is independent of the initial twist;
- investigating how the transverse motion depends on the initial twist;
- comparing experimental observations with numerical simulations.

Additional teaching notes, experimental guidance, and suggested exercises are provided in the `teaching/` directory.

---

## Reproducibility

This repository includes the main videos, data files, and simulation codes needed to reproduce the core results presented in the project.

The materials are intended to allow instructors and students to reproduce the experiment, perform motion analysis using Tracker, and compare the observations with numerical simulations.

---

## License

This repository is released under the MIT License.
