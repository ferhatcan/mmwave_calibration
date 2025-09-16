%% Load Couplings
load('couplings.mat')

%% Calibration - Matched
mismatch_GT = C_measurement ./ C_sim;
mismatch_GT(:,1) = mismatch_GT(:,1) ./ mismatch_GT(1,1);

adc_resolution = 12;
additional_path_delay_before_combination = 90;
[pwr_single, pwr_combined] = get_PD_readings(C_measurement(:, 1), adc_resolution, additional_path_delay_before_combination);
mismatches_M = get_mismatches(pwr_single, pwr_combined, C_sim(:, 1), additional_path_delay_before_combination);

upto = 9;

figure, 
hold on;
plot(1:upto, abs(mismatches_M(1:upto)) - abs(mismatch_GT(1:upto, 1)), Color="g", LineWidth=2, DisplayName='Error')
plot(1:upto, abs(mismatches_M(1:upto)), Color="b", LineWidth=2, DisplayName='Estimated')
plot(1:upto, abs(mismatch_GT(1:upto, 1)), Color="r", LineWidth=3, LineStyle='--', DisplayName='GT')
title('Gain Mismatch Errors')
xlabel('Receiver Index')
ylabel('Gain Mismatch Errors')
legend()
hold off;

figure, 
hold on;
plot(1:upto, rad2deg(angle(mismatches_M(1:upto))) - rad2deg(angle(mismatch_GT(1:upto, 1))), Color="g", LineWidth=2,  LineStyle='-', DisplayName='Error')
plot(1:upto, rad2deg(angle(mismatches_M(1:upto))), Color="b", LineWidth=2,  LineStyle='-', DisplayName='Estimated')
plot(1:upto, rad2deg(angle(mismatch_GT(1:upto, 1))), Color="r", LineWidth=3,  LineStyle='--', DisplayName='GT')
title('Phase Mismatch Estimation Errors')
xlabel('Receiver Index')
ylabel('Phase Mismatch Erros (in degrees)')
legend()
hold off;