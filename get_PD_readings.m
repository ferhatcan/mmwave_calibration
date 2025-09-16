%% a function to replicate RF frontend for calibration

function [pwr_single, pwr_combined] = get_PD_readings(vna_measurements, settings)
%% convert to individual powers

% Assume PD is linear
vna_measurements_dB = 20*log10(abs(vna_measurements)) + settings.tx_power - settings.coupler_losses; % 30 is added to convert to dbm
voltages_out = power_to_voltage(vna_measurements_dB, settings.min_power, settings.sensitivity, settings.pd_min, settings.pd_max);

% Apply ADC steps with minimum and maximum power 
Vq = quantize_voltage(voltages_out, settings.pd_min, settings.pd_max, settings.adc_resolution);

% map voltage to power back
pwr_single = voltage_to_power(Vq, settings.min_power, settings.sensitivity, settings.pd_min, settings.pd_max) + settings.coupler_losses;

%% convert to combined powers
combined_measurements = vna_measurements(1:end-1) + vna_measurements(2:end) .* 1*exp(-1j*deg2rad(settings.additional_path_delay_before_combination));

% Assume PD is linear
combined_measurements_dB = 20*log10(abs(combined_measurements)) + settings.tx_power - settings.coupler_losses - settings.comb_splitter_losses; % 30 is added to convert to dbm
voltages_out = power_to_voltage(combined_measurements_dB, settings.min_power, settings.sensitivity, settings.pd_min, settings.pd_max);

% Apply ADC steps with minimum and maximum power 
Vq = quantize_voltage(voltages_out, settings.pd_min, settings.pd_max, settings.adc_resolution);

% map voltage to power back
pwr_combined = voltage_to_power(Vq, settings.min_power, settings.sensitivity, settings.pd_min, settings.pd_max) + settings.comb_splitter_losses + settings.coupler_losses;


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
