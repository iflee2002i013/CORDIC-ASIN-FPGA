% a:    10=0+10+0
% cosa: 13=1+1+11
% sina: 13=1+1+11

function [cosa, sina] = cos_float(a)

%% cordic只做一个象限，其他象限按照三角函数进行转换
if (a < pi/2)
	a2 = a;
elseif (a >= pi/2) && (a < pi)
	a2 = pi-a;
elseif (a >= pi) && (a < 1.5*pi)
	a2 = a - pi;
elseif (a >= 1.5*pi) && (a < 2*pi)
	a2 = 2*pi-a;
end

%% cordic
itr = 12;
cosa = 0.60725293501;
sina = 0;
ar = a2;
for cnt = 0:itr-1
	tt = atan(2^(-cnt));
	tmp1 = (2^-cnt)*sina;
	tmp2 = (2^-cnt)*cosa;
	
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

%% result adjust
if (a < pi/2)
	cosa = cosa;
	sina = sina;
elseif (a >= pi/2) && (a < pi)
	cosa = -cosa;
	sina = sina;
elseif (a >= pi) && (a < 1.5*pi)
	cosa = -cosa;
	sina = -sina;
elseif (a >= 1.5*pi) && (a < 2*pi)
	cosa = cosa;
	sina = -sina;
end




