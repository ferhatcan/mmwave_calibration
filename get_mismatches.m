function mismatches = get_mismatches(pwr_single, pwr_combined, sim_couplings, additional_path_delay_before_combination)
if nargin < 4
    additional_path_delay_before_combination = 0; % default value
end

dB2abs = @(x) 10.^(x/20);
abs2dB = @(x) 20*log10(x);

% 1. calculate simulation path phase difference 
phase_diff_sim = zeros(size(sim_couplings, 1)-1, 1);
for k = 2:size(sim_couplings, 1)
    phase_diff_sim(k-1) = 1*exp(1j*(angle(sim_couplings(k, 1)) - angle(sim_couplings(k-1, 1)) - deg2rad(additional_path_delay_before_combination))); % keep it as complex to do add/sub easily
end

% 2. calculate simulation gain difference

% 3. Apply cosine term to obtain phase diff between antennas
% 4. Subtract path delay phase diff to find phase mismatches
phi_measured = zeros(size(pwr_combined,1),1);
phi_mismatch = zeros(size(pwr_combined,1),1);

for k = 1:size(pwr_combined, 1)
    a = dB2abs(pwr_combined(k, 1));
    b = dB2abs(pwr_single(k, 1));
    c = dB2abs(pwr_single(k+1, 1));
    ang = pi - acos((b^2 + c^2 - a^2) / (2 * b * c));
    
    % If path delay bigger than 180, the measured angle between power
    % measurement direction will likely changes. 
    % Closer to 180, increases ambugity (whether the mismatch lagging or leading)
    if mod(angle(phase_diff_sim(k, 1)), 2*pi) > pi
        phi_measured(k, 1) = 1 * exp(-1j*ang); % keep it as complex to do add/sub easily
    else
        phi_measured(k, 1) = 1 * exp(1j*ang); % keep it as complex to do add/sub easily
    end
    phi_mismatch(k, 1) = 1*exp(1j*(angle(phi_measured(k, 1)) - mod(angle(phase_diff_sim(k, 1)), 2*pi)));
end

% 5. cumilatively combine phase diffs to reference to 1st element all
phi_mismatch_ref = ones(size(pwr_single,1),1);
for k = 2:size(pwr_single, 1)
    phi_mismatch_ref(k, 1) = 1*exp(1j*sum(angle(phi_mismatch(1:k-1))));
end

% 6. from pwr single measurements and simulation gains, calculate gain
% mismatch

gain_mismatch = dB2abs(pwr_single) ./ abs(sim_couplings);
gain_mismatch = gain_mismatch ./ gain_mismatch(1);

mismatches = gain_mismatch .* exp(1j*angle(phi_mismatch_ref));

end