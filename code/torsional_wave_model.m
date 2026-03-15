clear; clc; close all;

%% ============================================================
%  torsional_wave_model.m
%
%  This script computes and visualizes the angular wave in a twisted slinky.
%  Default parameters correspond to Spring No.2 in the manuscript,
%  with initial twist u0 = 14*pi.
%
%  Main outputs:
%  1) 3D surface of u(theta,t)
%  2) Time series of u(theta0,t) at the top end
%  3) 3D surface of u_t(theta,t)
%  4) Time series of u_t(theta0,t) at the top end
%
%  USER GUIDE
%  To simulate another spring, mainly modify:
%    r1, r2, E, rho, theta0, u0
%
%  Their meanings are:
%    r1     inner radius (m)
%    r2     outer radius (m)
%    E      Young's modulus (Pa)
%    rho    density (kg/m^3)
%    theta0 total angular coordinate of the slinky (rad)
%    u0     initial top angular displacement (rad)
%% ============================================================

%% ---------------- USER-EDITABLE PARAMETERS -------------------
% Spring No.2 (current manuscript version)
r1 = 3.404e-2;      % m
r2 = 3.825e-2;      % m
E  = 2.719e9;       % Pa
rho = 1269;         % kg/m^3
theta0 = 66*pi;     % rad

% Initial twist
u0 = 7*pi;         % rad

% Numerical parameters
N_theta = 300;      % number of spatial grid points
N_t = 500;          % number of time steps
N_terms = 50;       % number of series terms

% Plot control
show_figures = true;
%% -------------------------------------------------------------

%% Derived quantities
theta = linspace(0, theta0, N_theta);

% Angular-wave parameter from the manuscript
omega_v = (r2 - r1) / (r2 + r1) * sqrt(2 * E / (3 * rho * (r1^2 + r2^2)));

% Angular-wave period
T = 4 * theta0 / omega_v;
t_max = 2 * T;                      % two periods
t = linspace(0, t_max, N_t);

%% Field variables
u   = zeros(N_theta, N_t);          % angular displacement
u_t = zeros(N_theta, N_t);          % angular velocity

%% Compute u(theta,t) and u_t(theta,t)
fprintf('Computing u(theta,t) and u_t(theta,t)...\n');

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

%% Extract top-end signals
u_top = u(end, :);
u_t_top = u_t(end, :);

%% Mesh for visualization
[T_mesh, Theta_mesh] = meshgrid(t, theta);

%% Visualization
if show_figures
    fprintf('Generating figures...\n');

    % -------- Figure 1: u(theta,t) and top-end displacement --------
    figure('Position', [100, 100, 1100, 700]);

    subplot(2,1,1);
    surf(Theta_mesh, T_mesh, u, 'EdgeColor', 'none');
    xlabel('\theta (rad)', 'Interpreter', 'tex');
    ylabel('t (s)');
    zlabel('u(\theta,t) (rad)', 'Interpreter', 'tex');
    title('Angular displacement u(\theta,t)');
    colormap parula;
    colorbar;
    view(135, 30);
    grid on;
    box on;

    subplot(2,1,2);
    plot(t, u_top, 'b-', 'LineWidth', 1.8);
    xlabel('t (s)');
    ylabel('u(\theta_0,t) (rad)', 'Interpreter', 'tex');
    title('Top-end angular displacement u(\theta_0,t)');
    grid on;
    box on;
    xlim([0, 2*T]);

    % -------- Figure 2: u_t(theta,t) and top-end angular velocity --------
    figure('Position', [150, 120, 1100, 700]);

    subplot(2,1,1);
    surf(Theta_mesh, T_mesh, u_t, 'EdgeColor', 'none');
    xlabel('\theta (rad)', 'Interpreter', 'tex');
    ylabel('t (s)');
    zlabel('\partialu/\partialt (rad/s)', 'Interpreter', 'tex');
    title('Angular velocity \partialu/\partialt');
    colormap turbo;
    colorbar;
    view(135, 30);
    grid on;
    box on;

    subplot(2,1,2);
    plot(t, u_t_top, 'r-', 'LineWidth', 1.8);
    xlabel('t (s)');
    ylabel('\partialu/\partialt|_{\theta=\theta_0} (rad/s)', 'Interpreter', 'tex');
    title('Top-end angular velocity at \theta = \theta_0');
    grid on;
    box on;
    xlim([0, 2*T]);
end

%% Output summary
fprintf('\n===== SUMMARY =====\n');
fprintf('Spring set              : No.2\n');
fprintf('Initial twist u0        : %.4f pi rad\n', u0/pi);
fprintf('Angular-wave period T   : %.6f s\n', T);
fprintf('Maximum |u|             : %.6e rad\n', max(abs(u(:))));
fprintf('Maximum |u_t|           : %.6e rad/s\n', max(abs(u_t(:))));
fprintf('Top-end max |u|         : %.6e rad\n', max(abs(u_top)));
fprintf('Top-end max |u_t|       : %.6e rad/s\n', max(abs(u_t_top)));
fprintf('===================\n');