clc;
clear;
close all;


%% 计算一个角度的cos
delt_a = 2*pi/2^10;
a = [0:delt_a:2*pi-delt_a];
len = length(a);
cosa = zeros(1,len);
sina = zeros(1,len);

% 产生激励时用四舍五入
a_fix = round(a/delt_a);

for cnt = 1:len
%     [cosa(cnt), sina(cnt)] = cos_float(a(cnt));
% 	[cosa_fix(cnt), sina_fix(cnt)] = cos_fix(a_fix(cnt)); cosa(cnt) = cosa_fix(cnt)/2^11; sina(cnt) = sina_fix(cnt)/2^11;
	[cosa_fix(cnt), sina_fix(cnt)] = cos_fix_max(a_fix(cnt)); cosa(cnt) = cosa_fix(cnt)/2^11; sina(cnt) = sina_fix(cnt)/2^11;
% 	[cosa_fix(cnt), sina_fix(cnt)] = cos_fix2(a_fix(cnt));cosa(cnt) = cosa_fix(cnt)/2^11;sina(cnt) = sina_fix(cnt)/2^11;
end
figure(1);plot(a*180/pi, cosa);grid on;hold on;plot(a*180/pi,sina,'r');hold off;

ref_cos = cos(a); 
ref_sin = sin(a);
err_cos = ref_cos - cosa;
err_sin = ref_sin - sina;
figure(2);plot(err_cos);grid on;hold on;plot(err_sin,'r');hold off;

if (max(abs(err_cos)) > 2^-11) ||  (max(abs(err_sin)) > 2^-11)
	bai = 1
else
	bai = 0
end






















