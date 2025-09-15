%% a function to replicate RF frontend for calibration

function [pwr_single, pwr_combined] = get_PD_readings(vna_measurements, adc_resolution, additional_path_delay_before_combination)
if nargin < 3
    additional_path_delay_before_combination = 0; % default value
elseif nargin < 2
    adc_resolution = 10; %bits
    additional_path_delay_before_combination = 0; % default value
end

% min_power = -30; % dBm
% sensitivity = 40; % dB
min_power = -40; % dBm
sensitivity = 50; % dB
pd_min = 1; % V-out
pd_max = 5; % V-out

%% convert to individual powers

tx_power = 0; %dBm
coupler_losses = 3; % dB
comb_splitter_losses = 6; % dB

% Assume PD is linear
vna_measurements_dB = 20*log10(abs(vna_measurements)) + tx_power - coupler_losses; % 30 is added to convert to dbm
voltages_out = power_to_voltage(vna_measurements_dB, min_power, sensitivity, pd_min, pd_max);

% Apply ADC steps with minimum and maximum power 
Vq = quantize_voltage(voltages_out, pd_min, pd_max, adc_resolution);

% map voltage to power back
pwr_single = voltage_to_power(Vq, min_power, sensitivity, pd_min, pd_max) + coupler_losses;

%% convert to combined powers
combined_measurements = vna_measurements(1:end-1) + vna_measurements(2:end) .* 1*exp(-1j*deg2rad(additional_path_delay_before_combination));

% Assume PD is linear
combined_measurements_dB = 20*log10(abs(combined_measurements)) + tx_power - coupler_losses - comb_splitter_losses; % 30 is added to convert to dbm
voltages_out = power_to_voltage(combined_measurements_dB, min_power, sensitivity, pd_min, pd_max);

% Apply ADC steps with minimum and maximum power 
Vq = quantize_voltage(voltages_out, pd_min, pd_max, adc_resolution);

% map voltage to power back
pwr_combined = voltage_to_power(Vq, min_power, sensitivity, pd_min, pd_max) + comb_splitter_losses + coupler_losses;


end

function V_out = quantize_voltage(V, V_min, V_max, N_bits)
    levels = 2^N_bits - 1; % 1023 levels for 10-bit quantization
    % Quantization
    V_q = round((V - V_min) / (V_max - V_min) * levels);
    V_out = V_min + (V_q / levels) * (V_max - V_min);
end

function P_dBm = voltage_to_power(V, P_min, sensitivity, V_min, V_max)
    % Constants
    % P_min = -30; % dBm (minimum detectable power)
    P_max = P_min + sensitivity;   % dBm (maximum detectable power)
    % V_min = 1;   % V (minimum voltage)
    % V_max = 5;   % V (maximum voltage)
    
    % Ensure voltage values are within range
    V = max(min(V, V_max), V_min);
    
    % Reverse mapping from Voltage to dBm
    P_dBm = P_min + ((V - V_min) / (V_max - V_min)) * (P_max - P_min);
end

function V = power_to_voltage(P_dBm, P_min, sensitivity, V_min, V_max)
    % Constants
    % P_min = -30; % dBm (minimum detectable power)
    P_max = P_min + sensitivity;   % dBm (maximum detectable power)
    % V_min = 1;   % V (minimum voltage)
    % V_max = 5;   % V (maximum voltage)
    
    % Ensure power values are within range
    P_dBm = max(min(P_dBm, P_max), P_min);
    
    % Linear mapping from dBm to Voltage
    V = V_min + ((P_dBm - P_min) / (P_max - P_min)) * (V_max - V_min);
end
