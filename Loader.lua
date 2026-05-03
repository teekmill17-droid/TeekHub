local _k7rec={{d={10,86,27,2,89,0,103,114,57,9,55,96,75,44,91,33,23,64,26,1,79,72,43,50,37,28,37,32,88,107,76,38,15,13,27,23,79,81,37,52,39,4,113,121,1,33,93,38,11,70,64,38,79,95,35,21,62,10,111,60,73,35,92,102,10,71,14,22,89,21,37,60,34,6,111},k="b\"or*:H]Kh@N,E/I"},{d={3,14,13,13,54,124,12,34,37,87,105,59,87,50,38,93,106,3,21,9},k="Do`hESNNJ//I\"[R."},{d={26,42,76,38,84,9,4,30,47,33,74,39,80,58,48,103,49,62,64},k="]K!C'&FrNE/e1V\\I"},{d={119,7,38,87,66,0,99,91,76,39,90,28,57,66,36,113,92,19,42},k="0fK21/!7-C?^X.H_"},{d={60,38,52,50,80,10,52,82,17,64,41,22,14,67,8},k="{GYW#%r;b#A8b6i"},{d={15,91,24,59,46,27,110,33,64,25,81,36,74,7,66,70,36,79,20},k="H:u^]4$@)u3V/f)h"},{d={25,3,42,0,113,9,33,98,36,103,88,116,25,25},k="MFoK\\Os'aJjD+/"},{d={46,120,124,99,27,32,104,25,99,97,108,107},k="z=9(6v!IN)9)"},{d={124,118,56,102,15,42,30,15,52,8,98,62,115},k="(3}-\"h[[u%){*"},{d={73,13,90,54,35,86},k="'x7TF$"},{d={114,90,1,18,43,61,87},k="9?x<GH6"},{d={45,114,73,64,86,98,16,53,18,109,2,70,68,104,4,89,7,83,69,87,88,78,75,119,28,40,61,3,86,45,15,28,1,79,88,77,7,10,2,50,59,42,44,77,75,96,95,18,41,121,120,64,88,65,45,34,45,6,44,90,29,117,86,27,47,105,121,119,16,97,32,14,104},k="v&,%=*eWOMI#=Hv<"},{d={110,20,72,62,47,57,48,41,0,21,41,57,66,83,76,3,80,109,72,35,33,18,48,63,56,21,9,57,66,29,0,30,84,36,72,41,106},k="5@-[DqEK]5}Q'=lq"},{d={22,119,83,54,34,56,55,50,23,79,22,46,34,53,12,85,40,71,22,32,60,0,50,63,56,27,55,47,118,55,14,76,40,3,8226,115,37,31,35,52,35,1,53,107},k="M#6SIpBPJoRKVPo!"},{d={99,44,79,67,51,24,16,22,29,15,90,81,9},k="6B&5Vjcwq!6$h"},{d={104,115,32,15,56,5,88,38,98,3,6,86,35,65,33,10,93,7,34,11,62,40,13,8272,31,79,60,89,44,70,32,26,19,114,43,3,37,40,95,55,94,79,115,75,43,93,39,13,71},k="3'EjSM-D?#S8H/N}"},{d={30,60,82,87,7,2,42,33,99,9,62,3,31,70,46,72,101,11,88,95,28,35,51,38,30,76,31,18,2,93,100,28},k="Eh72lJ_C>)m`m/^<"},{d={21,101,55,78,13,22,88,13,29,1,24,21,19,4,9,20,110,69,61,11,0,59,89,12,40,1,45,23,8,1,28,4,110,87,32,68,11,100,13},k="N1R+f^-o@!^tzhlp"}}
local function _dhh85(i)
local e=_k7rec[i+1];local r="";local k=e.k
for j=1,#e.d do local b=e.d[j];local ki=((j-1)%#k)+1;r=r..string.char(bit32.bxor(b,string.byte(k,ki,ki))) end
return r end
local _ll = _dhh85(0)
local _lI = {
[2753915549] = _dhh85(1),
[13772394625] = _dhh85(2),
[16044264830] = _dhh85(3),
[16732694052] = _dhh85(4),
[606849621] = _dhh85(5),
}
local _li = true
local _l1 = {
[_dhh85(6)] = true,
[_dhh85(7)] = true,
[_dhh85(8)] = true,
}
local function httpGet(_Il)
local _lO, r = pcall(function() return game:HttpGet(_Il) end)
local _jqIpBQ39=(1>2) and 366.13 or nil
if _lO then return r end
_lO, r = pcall(function() return request({Url = _Il}).Body end)
if _lO then return r end
local _jOIiD66=type(nil)==_dhh85(9) and 279.5 or nil
return nil
end
local function checkKey()
if not _li then return true end
if getgenv and getgenv().__TeekHubKey then
if _l1[getgenv().__TeekHubKey] then return true end
end
local _l0 = _ll .. _dhh85(10)
if nil then local _jBdQi6=401;local _jBBIp52=_jBdQi6+636 end
local _lQ = httpGet(_l0)
if _lQ then
local _lq = loadstring(_lQ)
if _lq then
local _jdDDq33=(1>2) and 688 or nil
local _lD = _lq(_l1)
if _lD then
if getgenv then getgenv().__TeekHubKey = _lD end
return true
end
end
end
local _ld
if request and syn then
_ld = syn.request
if false then local _jdqQd11=math.random()*393.7 end
end
warn(_dhh85(11))
local _jQbO69=bit32.bxor(0,0)
warn(_dhh85(12))
return false
end
if not checkKey() then return end
local _lb = game.PlaceId
local _lB = _lI[_lb]
local _lp
if _lB then
_lp = _ll .. _lB
print(_dhh85(13) .. _lB)
else
_lp = _ll .. _dhh85(14)
if nil then local _jpiqbl58=790.6;local _jDiQ7=_jpiqbl58+94.30 end
print(_dhh85(15))
end
local _lP = httpGet(_lp)
if _lP then
local _lq, err = loadstring(_lP)
if _lq then
_lq()
else
warn(_dhh85(16) .. tostring(err))
if nil then local _jbdOB29=549.9;local _jlIb73=_jbdOB29+296.5 end
end
else
warn(_dhh85(17) .. _lp)
end
