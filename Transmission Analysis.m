clear,clc

%Used threshold prices for each location, calculated/justified in TEA spreadsheet
threshBoston = 63;
threshSpain = 229;
threshSanDiego = 25;
threshAustralia = 80;

%Initialize data sources/locations, FX rate, and time zones
Loc1String = 'Boston';
Loc1=readmatrix(strcat(Loc1String,'.txt'));
Loc2String = 'Spain';
Loc2=readmatrix(strcat(Loc2String,'.txt'));

%Manually sets proper FX rate, time zone offet, and thresholds + variation
%in thresholds to see sensitivity
if strcmp(Loc1String,'Boston') && strcmp(Loc2String,'Spain')
    FX=1.0538; %USD per Foreign currency, 1 for Bos-SD, 1.0538 for Bos-Esp, 0.66 for SD-Aust
    timeDiff = 6; %hours ahead by Loc2, 6 for Bos-Esp, 3 for SD-Bos, -7 for SD-Aust
    
    minThresh1 = 5; %expected is %50
    maxThresh1 = threshBoston;
    stepThresh1 = 3;
    minThresh2 = 5; %expected is ~200 or greater
    maxThresh2 = threshSpain;
    stepThresh2 = stepThresh1;
elseif strcmp(Loc1String,'San Diego') && strcmp(Loc2String,'Australia')
    FX = 0.66;
    timeDiff = -7;
    minThresh1 = 5; %expected is %50
    maxThresh1 = threshSanDiego;
    stepThresh1 = 3;
    minThresh2 = 5; %expected is ~200 or greater
    maxThresh2 = threshAustralia;
    stepThresh2 = stepThresh1;
elseif strcmp(Loc1String,'San Diego') && strcmp(Loc2String,'Boston')
    FX=1;
    timeDiff = 3;
    minThresh1 = 5; %expected is %50
    maxThresh1 = threshSanDiego;
    stepThresh1 = 3;
    minThresh2 = 5; %expected is ~200 or greater
    maxThresh2 = threshBoston;
    stepThresh2 = stepThresh1;
end

%Adjust timezone of Loc2
hour=Loc1(:,1);
if timeDiff>0
    Loc2(:,2)=[Loc2(timeDiff+1:8760,2);Loc2(1:timeDiff,2)]*FX;
elseif timeDiff<0
    Loc2(:,2)=[Loc2(8761+timeDiff:8760,2);Loc2(1:8760+timeDiff,2)]*FX;
else
    Loc2=Loc2*FX;
end

%Arbitrage opportunity
diff=Loc2(:,2)-Loc1(:,2);
absDiff=abs(diff);
total=sum(absDiff)

%Direction of current flow
direction = (Loc2(:,2)-Loc1(:,2))./abs(Loc2(:,2)-Loc1(:,2)); %+ive is towards Loc 2, -ive is towards Loc 1
nans = find(isnan(direction)); %Deal with cases where price is exactly equal on two ends
for i =1:length(nans)
    direction(nans(i))=0;
end

%Initialize variables for CO2 abatement calculation
marg1=diff*0;
marg2=marg1;
marg=diff*0;
cumMarg=diff*0;
threshes1=linspace(minThresh1,maxThresh1,stepThresh1);
threshes2=linspace(minThresh2,maxThresh2,stepThresh2);
cumMarg = zeros(stepThresh1,stepThresh2);

%Compare if above/below CO2 threshold on each end to calculate CO2
%abatement
%
%If both locs are above/below threshold, no impact
%
%If one is above and other is below, CO2 is increase or decreased depending
%on direction of current flow

for t1=1:length(threshes1)
    for t2=1:length(threshes2)
        thresh1=threshes1(t1);
        thresh2=threshes2(t2);
        marg1 = Loc1(:,2) > thresh1;
        marg2 = Loc2(:,2) > thresh2;
        marg = (marg2 - marg1).*direction;
        cumMarg(t1,t2) = sum(marg);
    end
end
abatement = cumMarg*0.5; %0.5 tons per MWh

%Calculate & plot cumulative electron flow to see if it is dominant in one
%direction
cumulativeFlow = direction*0;
cumulativeFlow(1) = direction(1);
for i = 2:8760
    cumulativeFlow(i)=cumulativeFlow(i-1)+direction(i);
end
plot(hour,cumulativeFlow)