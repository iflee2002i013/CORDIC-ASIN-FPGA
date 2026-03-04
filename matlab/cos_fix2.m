% a：10=0+10+0
% cosa: 13=1+1+11
% sina: 13=1+1+11

function [cosa3,sina3] = cos_fix2(a)

%% cordic只做一个象限，其他象限按照三角函数进行转换
%9=0+9+0
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
cosa = 19898;
sina = 0;

%16=1+9+6
ar = a2*2^6;

%14=0+8+6
tt = [8192,4836,2555,1297,651,326,163,81,41,20,10,5,3,1];

for cnt = 0:13
	%15=1+0+14
	tmp1 = floor(sina/(2^cnt));
	
	%16=1+0+15
	tmp2 = floor(cosa/(2^cnt));
	
	if ar >= 0
		%17=1+1+15
		cosa = cosa - tmp1;
		sina = sina + tmp2;
		
		%16=1+9+6
		ar = ar - tt(cnt+1);
	else
		cosa = cosa + tmp1;
		sina = sina - tmp2;
		ar = ar + tt(cnt+1);
	end
end

%12=0+1+11
cosa2 = round(cosa / 2^4);
sina2 = round(sina / 2^4);


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







