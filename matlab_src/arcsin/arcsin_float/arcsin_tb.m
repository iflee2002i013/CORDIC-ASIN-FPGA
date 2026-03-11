clc;
clear;
close all;

%% 计算一个正弦值的arcsin
delt_sin = 2/2^12;
% 构造一个正弦值输入
target = [-0.95:delt_sin:0.95];
len = length(target);
% 创建一个长度为len的数组来存储arcsin的结果
arcsin = zeros(1,len);

% 产生激励时用四舍五入
target_fix = round(target/delt_sin);

for cnt = 1:len
    [arcsin(cnt)] = arcsin_proposed(target(cnt));
end
ref_asin = asin(target);

figure(1);
plot(target, arcsin*180/pi);grid on;hold on;
plot(target, ref_asin*180/pi,'r');hold off;
saveas(gcf, 'arcsin_vs_ref.png');



ref_arcsin = asin(target);
err_arcsin = ref_arcsin - arcsin;
figure(3);plot(err_arcsin);grid on;

max_err = max(abs(err_arcsin));
disp(['max error: ', num2str(max_err)]);
writematrix(err_arcsin, 'err_arcsin.csv');
writematrix(arcsin*180/pi, 'arcsin.csv');
writematrix(ref_asin*180/pi,"ref_asin.csv");
saveas(gcf, 'err_arcsin.png');