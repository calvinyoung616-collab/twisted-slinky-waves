clear; clc; close all;

%% ============================================================
%  transverse_wave_simulation.m
%
%  This script simulates the transverse motion of a twisted slinky.
%  Default parameters correspond to Spring No.2 in the manuscript,
%  with initial twist u0 = 14*pi.
%
%  Main steps:
%  1) Compute angular wave u(theta,t)
%  2) Compute effective transverse field v(theta,t)
%  3) Compute effective shear-force distribution
%  4) Compute complex displacement of the top coil
%  5) Estimate the dominant period using FFT
%
%  ------------------------------------------------------------
%  USER GUIDE
%  If you want to simulate another spring, mainly modify:
%    r1, r2, h, E, G, rho, theta0, u0
%
%  Their meanings are:
%    r1     inner radius of coil cross section (m)
%    r2     outer radius of coil cross section (m)
%    h      coil thickness / pitch (m)
%    E      Young's modulus (Pa)
%    G      shear modulus (Pa)
%    rho    density (kg/m^3)
%    theta0 total angular coordinate of the slinky (rad)
%    u0     initial top angular displacement (rad)
%
%  The current script uses Spring No.2 and u0 = 14*pi.
%% ============================================================

%% ---------------- USER-EDITABLE PARAMETERS -------------------
% Spring No.2
r1 = 3.404e-2;      % m
r2 = 3.825e-2;      % m
h  = 2.33e-3;       % m
E  = 2.719e9;       % Pa
G  = 0.943e9;       % Pa
rho = 1269;         % kg/m^3
theta0 = 66*pi;     % rad

% Initial twist
u0 = 14*pi;         % rad

% Model / numerical parameters
gamma_damp = 0.5;   % damping coefficient in top-coil motion
kappa = 0.833;        % shear correction factor
v0 = 1.2e-5;             % initial amplitude in v(theta,0)=v0*sin(theta)

N_theta = 200;      % number of spatial grid points
N_t = 400;          % initial number of time steps
N_terms = 30;       % number of series terms for u(theta,t)

% Visualization / output options
show_figures = true;
%% -------------------------------------------------------------

%% Basic derived quantities
R = (r1 + r2) / 2;          % mean radius (m)
b = r2 - r1;                % radial width of rectangular cross section (m)
A_cs = h * b;               % effective cross-sectional area (m^2)

% Angular-wave parameter from the manuscript
omega_v = (r2 - r1) / (r2 + r1) * sqrt(2 * E / (3 * rho * (r1^2 + r2^2)));

% Coefficient in v_tt - c^2 v_thetatheta = source
c_sq = kappa * G / (rho * R^2);

% Angular-wave period
T = 4 * theta0 / omega_v;
t_max = 2 * T;

%% Grid setup
theta = linspace(0, theta0, N_theta);
t = linspace(0, t_max, N_t);

dtheta = theta(2) - theta(1);
dt = t(2) - t(1);

CFL = sqrt(c_sq) * dt / dtheta;
fprintf('Initial CFL number: %.4f\n', CFL);

if CFL > 0.9
    dt = 0.9 * dtheta / sqrt(c_sq);
    t = 0:dt:t_max;
    N_t = length(t);
    fprintf('Adjusted dt to %.6e s\n', dt);
    fprintf('New CFL number: %.4f\n', sqrt(c_sq) * dt / dtheta);
end

%% Field variables
% u(theta,t): angular displacement
% u_t(theta,t): angular velocity
% v(theta,t): effective transverse variable
u   = zeros(N_theta, N_t);
u_t = zeros(N_theta, N_t);

v   = zeros(N_theta, N_t);
v_t = zeros(N_theta, N_t);

%% Initial condition for v(theta,t)
for i = 1:N_theta
    v(i,1) = v0 * sin(theta(i));
end
v(:,2) = v(:,1);    % implements v_t(theta,0)=0 approximately

%% 1) Compute u(theta,t) and u_t(theta,t)
fprintf('Computing angular wave field u(theta,t)...\n');

for n = 0:N_terms
    k_n = (2*n + 1) * pi / (2 * theta0);
    A_n = (-1)^n * 8 / ((2*n + 1)^2 * pi^2) * u0;

    for j = 1:N_t
        cos_term = cos(k_n * omega_v * t(j));
        sin_term = sin(k_n * omega_v * t(j));

        for i = 1:N_theta
            spatial_factor = sin(k_n * theta(i));
            u(i,j)   = u(i,j)   + A_n * spatial_factor * cos_term;
            u_t(i,j) = u_t(i,j) - A_n * k_n * omega_v * spatial_factor * sin_term;
        end
    end

    if mod(n,10) == 0
        fprintf('  Series term %d / %d completed\n', n, N_terms);
    end
end

%% 2) Compute r'(theta,t) and solve v(theta,t)
fprintf('Computing r''(theta,t) and solving transverse field v(theta,t)...\n');

[Theta_mesh, T_mesh] = meshgrid(theta, t);
series_sum = zeros(size(Theta_mesh));

for n = 0:N_terms
    A_n = (-1)^n * 8 / ((2*n + 1)^2 * pi^2) * u0;
    k_n = (2*n + 1) * pi / (2 * theta0);

    series_sum = series_sum + ...
        A_n * k_n * cos(k_n * Theta_mesh) .* cos(k_n * omega_v * T_mesh);
end

r_prime = R ./ (1 + series_sum);
r_prime = r_prime.';   % reshape to N_theta x N_t

u_t_sq_r_prime = (u_t).^2 .* r_prime;

for j = 2:N_t-1
    for i = 2:N_theta-1
        v_thetatheta = (v(i+1,j) - 2*v(i,j) + v(i-1,j)) / dtheta^2;

        v(i,j+1) = 2*v(i,j) - v(i,j-1) + dt^2 * ...
                   (c_sq * v_thetatheta + u_t_sq_r_prime(i,j));
    end

    % Boundary conditions:
    % v(0,t)=0, v_theta(theta0,t)=0
    v(1, j+1) = 0;
    v(N_theta, j+1) = v(N_theta-1, j+1);

    if mod(j,100) == 0
        fprintf('  Time step %d / %d completed\n', j, N_t);
    end
end

%% Compute v_t
for j = 2:N_t-1
    v_t(:,j) = (v(:,j+1) - v(:,j-1)) / (2*dt);
end
v_t(:,1)   = (v(:,2) - v(:,1)) / dt;
v_t(:,N_t) = (v(:,N_t) - v(:,N_t-1)) / dt;

%% Spatial derivative dv/dtheta
dv_dtheta = zeros(N_theta, N_t);

for j = 1:N_t
    for i = 2:N_theta-1
        dv_dtheta(i,j) = (v(i+1,j) - v(i-1,j)) / (2*dtheta);
    end

    dv_dtheta(1,j) = (v(2,j) - v(1,j)) / dtheta;
    dv_dtheta(N_theta,j) = (v(N_theta,j) - v(N_theta-1,j)) / dtheta;
end

%% 3) Compute effective shear-force distribution
fprintf('Computing effective shear-force field Q(theta,t)...\n');

Q = kappa * G * h * b / R * dv_dtheta;

%% 4) Compute complex displacement of the top coil
fprintf('Computing complex displacement of the top coil...\n');

theta_start_top = theta0 - 2*pi;
theta_end_top   = theta0;

[~, start_idx_top] = min(abs(theta - theta_start_top));
[~, end_idx_top]   = min(abs(theta - theta_end_top));

mass_top = rho * A_cs * 2*pi*R;

z_tilde_top    = zeros(1, N_t);
z_tilde_t_top  = zeros(1, N_t);
z_tilde_tt_top = zeros(1, N_t);

for j = 2:N_t-1
    theta_prime_start = theta(start_idx_top) + u(start_idx_top, j);
    theta_prime_end   = theta(end_idx_top)   + u(end_idx_top, j);

    term1 = Q(start_idx_top, j) * exp(1i * theta_prime_start);
    term2 = Q(end_idx_top,   j) * exp(1i * theta_prime_end);

    total_rhs = term1 - term2;

    % Equation: m z¨ + gamma_damp z˙ = total_rhs
    z_tilde_tt_top(j) = (total_rhs - gamma_damp * z_tilde_t_top(j-1)) / mass_top;

    % Explicit Euler update
    z_tilde_t_top(j) = z_tilde_t_top(j-1) + z_tilde_tt_top(j) * dt;
    z_tilde_top(j)   = z_tilde_top(j-1) + z_tilde_t_top(j) * dt;
end

% fill last point
z_tilde_tt_top(N_t) = z_tilde_tt_top(N_t-1);
z_tilde_t_top(N_t)  = z_tilde_t_top(N_t-1);
z_tilde_top(N_t)    = z_tilde_top(N_t-1);

%% 5) FFT analysis
fprintf('Performing FFT analysis...\n');

v_x = real(z_tilde_t_top);
v_x_detrended = v_x - mean(v_x);

Fs = 1 / dt;
N_fft = length(v_x_detrended);

Y = fft(v_x_detrended);
P2 = abs(Y / N_fft);
P1 = P2(1:floor(N_fft/2)+1);
P1(2:end-1) = 2 * P1(2:end-1);

f = Fs * (0:floor(N_fft/2)) / N_fft;

% ignore zero-frequency component
if length(P1) >= 2
    [~, idx_local] = max(P1(2:end));
    dominant_idx = idx_local + 1;
else
    dominant_idx = 1;
end

dominant_freq = f(dominant_idx);

if dominant_freq > 0
    dominant_period = 1 / dominant_freq;
else
    dominant_period = Inf;
end

fprintf('Dominant frequency: %.6f Hz\n', dominant_freq);
fprintf('Dominant period   : %.6f s\n', dominant_period);

%% Visualization
if show_figures
    fprintf('Generating figures...\n');

    figure('Position', [100, 100, 1000, 600]);

    subplot(2,2,1);
    plot(real(z_tilde_top), imag(z_tilde_top), 'b-', 'LineWidth', 2);
    hold on;
    plot(real(z_tilde_top(1)), imag(z_tilde_top(1)), 'go', 'MarkerSize', 8, 'MarkerFaceColor', 'g');
    plot(real(z_tilde_top(end)), imag(z_tilde_top(end)), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
    xlabel('Real Part (m)');
    ylabel('Imaginary Part (m)');
    title('Displacement Trajectory in Complex Plane');
    legend('Trajectory', 'Start', 'End', 'Location', 'best');
    grid on; axis equal;

    subplot(2,2,2);
    plot(real(z_tilde_t_top), imag(z_tilde_t_top), 'r-', 'LineWidth', 2);
    hold on;
    plot(real(z_tilde_t_top(1)), imag(z_tilde_t_top(1)), 'go', 'MarkerSize', 8, 'MarkerFaceColor', 'g');
    plot(real(z_tilde_t_top(end)), imag(z_tilde_t_top(end)), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
    xlabel('Real Part (m/s)');
    ylabel('Imaginary Part (m/s)');
    title('Velocity Trajectory in Complex Plane');
    legend('Trajectory', 'Start', 'End', 'Location', 'best');
    grid on; axis equal;

    subplot(2,2,3);
    plot(t, real(z_tilde_top), 'b-', 'LineWidth', 2);
    xlabel('Time (s)');
    ylabel('Real Part of Displacement (m)');
    title('Real Part of Displacement vs Time');
    grid on;

    subplot(2,2,4);
    plot(t, real(z_tilde_t_top), 'r-', 'LineWidth', 2);
    xlabel('Time (s)');
    ylabel('Real Part of Velocity (m/s)');
    title('Real Part of Velocity vs Time');
    grid on;

    figure('Position', [100, 100, 1000, 600]);
    plot(f, P1, 'k-', 'LineWidth', 2);
    hold on;
    plot(dominant_freq, P1(dominant_idx), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
    text(dominant_freq, P1(dominant_idx)*1.1, ...
        sprintf('Dominant: %.3f Hz', dominant_freq), ...
        'HorizontalAlignment', 'center');
    xlabel('Frequency (Hz)');
    ylabel('Amplitude');
    title('FFT Spectrum of Real Part of Velocity');
    grid on;
    xlim([0, min(10*dominant_freq + eps, Fs/2)]);
end

%% Output summary
fprintf('\n===== SUMMARY =====\n');
fprintf('Spring set           : No.2\n');
fprintf('Initial twist u0     : %.4f pi rad\n', u0/pi);
fprintf('Angular-wave period  : %.6f s\n', T);
fprintf('Dominant FFT period  : %.6f s\n', dominant_period);
fprintf('Max |z_tilde|        : %.6e m\n', max(abs(z_tilde_top)));
fprintf('Max |z_tilde_t|      : %.6e m/s\n', max(abs(z_tilde_t_top)));
fprintf('Sampling frequency   : %.6f Hz\n', Fs);
fprintf('Frequency resolution : %.6f Hz\n', f(2)-f(1));
fprintf('===================\n');
