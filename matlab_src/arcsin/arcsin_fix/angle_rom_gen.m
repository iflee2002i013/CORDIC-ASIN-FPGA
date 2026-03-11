% ===============================================================
% 预计算 ROM 表并打印成序列
M = 12;
exp_ar = 9;
angle_rom_array = zeros(1, M-1);
for i = 1:M-1
    angle_rom_array(i) = round(atan(2^-i) * 2^exp_ar);
end
fprintf('\n--- 预计算 ROM 表 (angle_rom) ---\n');
fprintf('%d, ', angle_rom_array(1:end-1));
fprintf('%d\n', angle_rom_array(end));
fprintf('--------------------------------\n\n');
% ===============================================================