% a:    10=0+10+0
% cosa: 13=1+1+11
% sina: 13=1+1+11

function [cosa3,sina3] = cos_fix(a)

%% cordic只做一个象限，其他象限按照三角函数进行转换
% a2: 9=0+9+0
if (a < 256)
	a2 = a;
elseif (a >= 256) && (a < 512)
	a2 = 512 - a;
elseif (a >= 512) && (a < 768)
	a2 = a - 512;
elseif (a >= 768) && (a < 1024)
	a2 = 1024 - a;
end

%% cordic
itr = 14;

exp_cos = 15;
cosa = round(0.60725293501*2^exp_cos);

% sina: 17=1+1+15
sina = 0;

%ar:
exp_a = 6;
ar = a2*2^exp_a;

for cnt = 0:itr-1
	% tt: (itr-1)=0+0+(itr-1)
	tt = round(atan(2^(-cnt))/(2*pi/1024)*2^exp_a);
	
    tmp1 = floor(sina/(2^cnt));
    tmp2 = floor(cosa/(2^cnt));
    
    if ar >= 0
        cosa = cosa - tmp1;
        sina = sina + tmp2;   
        ar = ar - tt;
    else
        cosa = cosa + tmp1;
        sina = sina - tmp2;   
        ar = ar + tt;
	end
end

cosa2 = round(cosa / 2^(exp_cos-11));
sina2 = round(sina / 2^(exp_cos-11));


%% result adjust
if (a < 256)
	cosa3 = cosa2;
	sina3 = sina2;
elseif (a >= 256) && (a < 512)
	cosa3 = -cosa2;
	sina3 = sina2;
elseif (a >= 512) && (a < 768)
	cosa3 = -cosa2;
	sina3 = -sina2;
elseif (a >= 768) && (a < 1024)
	cosa3 = cosa2;
	sina3 = -sina2;
end







