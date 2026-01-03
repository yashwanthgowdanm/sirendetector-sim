% =========================================================================
% ACOUSTIC EMERGENCY VEHICLE PREEMPTION SYSTEM (DETERMINISTIC DSP)
% Author: Yashwanth Gowda (Simulation)
% Description: Simulates detection of a siren 1000ft away using FFT/STFT
%              and controls traffic light logic without AI.
% =========================================================================

clc; clear; close all;

%% 1. CONFIGURATION & PHYSICS CONSTANTS
fs = 8000;              % Sampling rate (8kHz is sufficient for sirens)
duration = 10;          % Duration of simulation in seconds
t = 0:1/fs:duration-1/fs; % Time vector

% Siren Parameters (Standard "Wail" Siren)
f_start = 600;          % Low frequency (Hz)
f_end = 1500;           % High frequency (Hz)
wail_rate = 4.5;        % Cycles per second (How fast it goes woo-woo)

% Distance Simulation (1000 ft away = High Attenuation)
% We simulate distance by reducing the siren amplitude relative to noise.
siren_amplitude = 0.3;  % Weak signal (simulating distance)
noise_level = 0.4;      % High background noise (Traffic/Wind)

%% 2. SIGNAL GENERATION (The Environment)

% Generate the Siren Signal (Frequency Modulation)
% Using a sawtooth wave to modulate frequency between 600-1500Hz
modulator = sawtooth(2*pi*wail_rate*t, 0.5); % 0.5 makes it triangle wave
freq_inst = f_start + (f_end - f_start) * (modulator + 1)/2;
siren_clean = siren_amplitude * sin(2*pi * cumtrapz(t, freq_inst));

% Create Scenarios: 
% 0-2s: Silence/Traffic Only
% 2-8s: Siren Approaches (Active)
% 8-10s: Silence/Traffic Only
active_mask = (t >= 2) & (t <= 8); 
siren_signal = siren_clean .* active_mask;

% Add Traffic Noise (White Gaussian Noise)
traffic_noise = noise_level * randn(size(t));

% Combined Signal received at the sensor
received_signal = siren_signal + traffic_noise;

%% 3. DSP DETECTION ALGORITHM (The "Non-AI" Logic)
% We use Short-Time Fourier Transform (STFT) to analyze chunks of time.

window_size = 256;      % Window size for FFT
overlap = 128;          % Overlap for smoothness
[S, F, T_spec] = spectrogram(received_signal, window_size, overlap, [], fs);

% Calculate Energy in the Target Band (600Hz - 1500Hz)
% We ignore all other frequencies (filtering out engine rumble/wind).
target_indices = find(F >= 600 & F <= 1500);
band_energy = mean(abs(S(target_indices, :)), 1);

% Normalize energy for easier thresholding
band_energy = band_energy / max(band_energy);

% Detection Logic
detection_threshold = 0.65; % Sensitivity (Tune this based on testing)
is_siren_detected = band_energy > detection_threshold;

% Smooth the detection (Debouncing) to prevent flickering
% We require X consecutive "True" frames to confirm detection.
window_smooth = 10; 
is_siren_confirmed = movmean(is_siren_detected, window_smooth) > 0.6;

%% 4. TRAFFIC LIGHT CONTROL STATE MACHINE
% Mapping spectrogram time back to simulation time
num_steps = length(T_spec);
traffic_light_state = strings(1, num_steps);
current_light = "RED"; % Start with RED
red_timer = 5;         % Seconds remaining on Red

results_log = []; % To store metrics

for i = 1:num_steps
    % Decrease timer (approximate based on time step)
    dt = T_spec(2) - T_spec(1);
    
    % --- THE CORE LOGIC ---
    if is_siren_confirmed(i)
        % INTERVENTION: Siren Heard!
        if current_light == "RED"
             current_light = "GREEN (EMERGENCY)";
             red_timer = 0; % Force change
        elseif current_light == "GREEN" || current_light == "GREEN (EMERGENCY)"
             current_light = "GREEN (HELD)";
             % Keep timer high so it doesn't turn Red
        end
    else
        % NORMAL OPERATION
        if current_light == "GREEN (EMERGENCY)" || current_light == "GREEN (HELD)"
             % Siren gone, return to normal cycle (simplified)
             current_light = "GREEN"; 
        end
    end
    
    traffic_light_state(i) = current_light;
end

%% 5. METRICS CALCULATION (Proofs for your Thesis/Project)

% Signal to Noise Ratio (SNR)
signal_power = rms(siren_signal(active_mask))^2;
noise_power = rms(traffic_noise)^2;
SNR_dB = 10 * log10(signal_power / noise_power);

% Detection Latency (How fast did it react?)
% Find first time siren was active vs first time system confirmed it
first_active_idx = find(active_mask, 1);
time_siren_start = t(first_active_idx);

% Find first detection AFTER siren started
detection_indices = find(T_spec >= time_siren_start & is_siren_confirmed);
if ~isempty(detection_indices)
    time_detected = T_spec(detection_indices(1));
    latency_ms = (time_detected - time_siren_start) * 1000;
else
    latency_ms = Inf;
end

% False Positives (Did it trigger when no siren was there?)
% Check time periods where siren was OFF but detection was ON
false_positive_count = sum(is_siren_confirmed & (T_spec < 2 | T_spec > 8));

%% 6. VISUALIZATION

figure('Position', [100, 100, 1200, 800]);

% Plot 1: The Noisy Signal (What the sensor hears)
subplot(3,1,1);
plot(t, received_signal, 'Color', [0.6 0.6 0.6]); hold on;
plot(t, siren_signal, 'r', 'LineWidth', 1.5);
title(['Input Audio (SNR: ' num2str(SNR_dB, '%.2f') ' dB)']);
legend('Noisy Signal (1000ft)', 'True Siren Signal');
xlabel('Time (s)'); ylabel('Amplitude');
grid on;

% Plot 2: Spectral Energy Detection (The "Brain")
subplot(3,1,2);
plot(T_spec, band_energy, 'b', 'LineWidth', 1.5); hold on;
yline(detection_threshold, 'r--', 'Threshold');
area(T_spec, is_siren_confirmed, 'FaceColor', 'g', 'FaceAlpha', 0.3);
title('Algorithm Confidence (600-1500Hz Band Energy)');
legend('Band Energy', 'Threshold', 'Siren Confirmed');
ylabel('Normalized Energy'); grid on;

% Plot 3: Traffic Light Status
subplot(3,1,3);
% Convert status strings to numbers for plotting
status_codes = zeros(1, num_steps);
status_codes(traffic_light_state == "RED") = 1;
status_codes(traffic_light_state == "GREEN") = 2;
status_codes(traffic_light_state == "GREEN (EMERGENCY)") = 3;
status_codes(traffic_light_state == "GREEN (HELD)") = 3;

plot(T_spec, status_codes, 'k', 'LineWidth', 2);
yticks([1 2 3]);
yticklabels({'RED', 'GREEN', 'EMERGENCY GREEN'});
title(['Traffic Light State (Response Time: ' num2str(latency_ms, '%.0f') ' ms)']);
xlabel('Time (s)');
ylim([0.5 3.5]);
grid on;

%% 7. DISPLAY METRICS
fprintf('========================================\n');
fprintf('SIMULATION RESULTS FOR %s\n', 'YASHWANTH GOWDA');
fprintf('========================================\n');
fprintf('Simulated Distance: ~1000 ft (High Noise Env)\n');
fprintf('Signal-to-Noise Ratio: %.2f dB\n', SNR_dB);
fprintf('System Latency: %.2f ms\n', latency_ms);
fprintf('False Positive Frames: %d\n', false_positive_count);
fprintf('========================================\n');