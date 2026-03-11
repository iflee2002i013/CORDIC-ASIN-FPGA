% a:    10=0+10+0
% cosa: 13=1+1+11
% sina: 13=1+1+11

function [cosa3,sina3] = cos_fix_max(a)

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

cfg_a2_wid = 9;
if a2 >= 2^cfg_a2_wid 
	a2 = mod(a2,2^cfg_a2_wid);
elseif a2 >= 0 
	a2 = a2;
else
	fprintf('a2 < 0: %d\n',a2);
end


%% cordic
itr = 14;

exp_cos = 15;
cosa = round(0.60725293501*2^exp_cos);

cfg_cosa_wid = 17;
if (cosa >= 2^(cfg_cosa_wid-1)) || (cosa < -2^(cfg_cosa_wid-1))
	cosa = cosa-(floor((cosa-2^(cfg_cosa_wid-1))/2^cfg_cosa_wid)+1)*2^cfg_cosa_wid;
else
	cosa = cosa;
end

% sina: 17=1+1+15
sina = 0;

%ar:
exp_a = 6;
ar = a2*2^exp_a;

cfg_ar_wid = 16;
if (ar >= 2^(cfg_ar_wid-1)) || (ar < -2^(cfg_ar_wid-1))
	ar = ar-(floor((ar-2^(cfg_ar_wid-1))/2^cfg_ar_wid)+1)*2^cfg_ar_wid;
else
	ar = ar;
end

for cnt = 0:itr-1
	% tt: (itr-1)=0+0+(itr-1)
	tt = round(atan(2^(-cnt))/(2*pi/1024)*2^exp_a);
	
	cfg_tt_wid = 14;
	if tt >= 2^cfg_tt_wid 
		tt = mod(tt,2^cfg_tt_wid);
	elseif tt >= 0 
		tt = tt;
	else
		fprintf('tt < 0: %d\n',tt);
	end
	
    tmp1 = floor(sina/(2^cnt));
    tmp2 = floor(cosa/(2^cnt));
	
	cfg_tmp1_wid = 15;
	if (tmp1 >= 2^(cfg_tmp1_wid-1)) || (tmp1 < -2^(cfg_tmp1_wid-1))
		tmp1 = tmp1-(floor((tmp1-2^(cfg_tmp1_wid-1))/2^cfg_tmp1_wid)+1)*2^cfg_tmp1_wid;
	else
		tmp1 = tmp1;
	end
	
	cfg_tmp2_wid = 16;
	if (tmp2 >= 2^(cfg_tmp2_wid-1)) || (tmp2 < -2^(cfg_tmp2_wid-1))
		tmp2 = tmp2-(floor((tmp2-2^(cfg_tmp2_wid-1))/2^cfg_tmp2_wid)+1)*2^cfg_tmp2_wid;
	else
		tmp2 = tmp2;
	end
    
    if ar >= 0
        cosa = cosa - tmp1;
        sina = sina + tmp2;   
        ar = ar - tt;
    else
        cosa = cosa + tmp1;
        sina = sina - tmp2;   
        ar = ar + tt;
	end
	
	if (cosa >= 2^(cfg_cosa_wid-1)) || (cosa < -2^(cfg_cosa_wid-1))
		cosa = cosa-(floor((cosa-2^(cfg_cosa_wid-1))/2^cfg_cosa_wid)+1)*2^cfg_cosa_wid;
	else
		cosa = cosa;
	end

	cfg_sina_wid = 17;
	if (sina >= 2^(cfg_sina_wid-1)) || (sina < -2^(cfg_sina_wid-1))
		sina = sina-(floor((sina-2^(cfg_sina_wid-1))/2^cfg_sina_wid)+1)*2^cfg_sina_wid;
	else
		sina = sina;
	end
	
	if (ar >= 2^(cfg_ar_wid-1)) || (ar < -2^(cfg_ar_wid-1))
		ar = ar-(floor((ar-2^(cfg_ar_wid-1))/2^cfg_ar_wid)+1)*2^cfg_ar_wid;
	else
		ar = ar;
	end
end

cosa2 = round(cosa / 2^(exp_cos-11));
sina2 = round(sina / 2^(exp_cos-11));

cfg_cosa2_wid = 12;
if cosa2 >= 2^cfg_cosa2_wid 
	cosa2 = mod(cosa2,2^cfg_cosa2_wid);
elseif cosa2 >= 0 
	cosa2 = cosa2;
else
	fprintf('cosa2 < 0: %d\n',cosa2);
end

cfg_sina2_wid = 12;
if sina2 >= 2^cfg_sina2_wid 
	sina2 = mod(sina2,2^cfg_sina2_wid);
elseif sina2 >= 0 
	sina2 = sina2;
else
	fprintf('sina2 < 0: %d\n',sina2);
end



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

cfg_cosa3_wid = 13;
if (cosa3 >= 2^(cfg_cosa3_wid-1)) || (cosa3 < -2^(cfg_cosa3_wid-1))
	cosa3 = cosa3-(floor((cosa3-2^(cfg_cosa3_wid-1))/2^cfg_cosa3_wid)+1)*2^cfg_cosa3_wid;
else
	cosa3 = cosa3;
end

cfg_sina3_wid = 13;
if (sina3 >= 2^(cfg_sina3_wid-1)) || (sina3 < -2^(cfg_sina3_wid-1))
	sina3 = sina3-(floor((sina3-2^(cfg_sina3_wid-1))/2^cfg_sina3_wid)+1)*2^cfg_sina3_wid;
else
	sina3 = sina3;
end





