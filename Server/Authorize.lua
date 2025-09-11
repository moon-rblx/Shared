local Players=game:GetService('Players')
local HttpService=game:GetService('HttpService')
local function authorize(uid)
if type(uid)~='number' and type(uid)~='string' then return end
local s=tostring(uid)
if #s==0 then return end
local p=Players:GetPlayerByUserId(tonumber(s))
if not p then return end
local r=nil
local ok=pcall(function()
r=request({
Url='https://bloxsync.com/Services/authorize.php',
Method='POST',
Headers={['Content-Type']='application/json',['Accept']='application/json',['Host']='bloxsync.com'},
Body=HttpService:JSONEncode({uid=s})
})
end)
if not ok or not r or not r.Success or r.StatusCode~=200 or not r.Body then return end
local ok2,d=pcall(function() return HttpService:JSONDecode(r.Body) end)
if not ok2 or type(d)~='table' then return end
if d.Authorized==true and type(d.Code)=='string' and #d.Code>0 then p:SetAttribute('Authorization',d.Code) end
end
return authorize
