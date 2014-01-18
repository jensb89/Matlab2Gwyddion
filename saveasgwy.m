function [ n ] = saveasgwy(filename,data,numstepsx,numstepsy,startx,endx,starty,endy,label,unit,time,varargin)
%saveasgwy Save NxM or NxMxL matrix as Gwyddion native data file.  
%   Save data (NxMxL matrix) for Gwyddion (SPM (scanning probe microscopy)
%   data visualization and analysis)
%   More information about Gwyddion and the Gwyddion data format can be
%   found under http://gwyddion.net and
%   http://gwyddion.net/documentation/user-guide-en/gwyfile-format.html
%   
%   Inputs:
%   -filename
%   -data as a NxMxL or NxM Matrix with 
%   N = #ypoints
%   M = #xpoints
%   L = #channels
%   - numstepsx : Number of Points in x-direction
%   - numstepsy
%   - startx : Startpoint for x-Axis in µm (e.g. 3.2 for 3.2µm)
%   - endx
%   - starty
%   - endy
%   - label : cell array of size L with a string for each channel (e.g.
%   {'Chan1','Chan2'} , L=2)
%   - Unit : cell array of size L with a unitstring for each channel
%   {'V','m'} etc.
%   - time : actual Date+Time for metadata as serial date number (see 'now'
%   or 'datenum' for mor information about serial date numbers)
%   - extra Metadata information (cell array) // not used at the moment //
%   
%   Example call:
%   n=saveasgwy('test.gwy',rand(30,200,2),200,30,1,2,3,4,...
%               {'test1','test2'},{'V','m'},now);
%
%   Version 1.0
%
%   Copyright (C) Jens Brauer, www.jens-brauer.de, 2014

xyunit = 'm';

if nargin < 11 
    time = now;
end

s = size(data);
if length(s)>2
    numchannels = s(3);
    numpoints = numel(data(:,:,1));
else
    numchannels = 1;
    numpoints = numel(data);
end

file = fopen(filename,'w','a'); 

expectedTopContainerSize=0;
sizeGwyUnitContainerxy = 10+length(xyunit);
sizeGwyDataFieldContainer0 = (numpoints*8 + 4 +6) ...
                             +sizeGwyUnitContainerxy ... %8Byte double array + 4 Byte for serialized size
                             +129;  %restbytes (sum(n([7:14,16,17])))
sizeGwyContainer = numchannels*sizeGwyDataFieldContainer0 +... %DataContainerSize w/o Unit-z-Container
                  length(cell2mat(unit))+10*numchannels +... %size of all Unit-z-Containers
                  numchannels*131 + length(cell2mat(label));  %rest bytes from all around the data container
                  %97=sum(n([4,5,6,21:25]))-length(labels{end});

% START FILE
n(1)=fprintf(file,'GWYP');
n(2)=fprintf(file,'GwyContainer%s',0); %TOP CONTAINER, '%s',0 == NUL 
n(3)=fwrite(file,sizeGwyContainer,'uint32');

i=1;
while i<numchannels+1
    sizeGwyUnitContainerz = 10+length(unit{i}); 
    sizeGwyDataFieldContainer = sizeGwyDataFieldContainer0 + sizeGwyUnitContainerz;
    
    %n(4)=fprintf(file,'/%u/base/palette/%s%c%s%s',i-1,0,'s','Gold',0);
    n(5)=fprintf(file,'/%u/data%s%c%s%s',i-1,0,'o','GwyDataField',0); 
    n(6)=fwrite(file,sizeGwyDataFieldContainer,'uint32');
    n(6)=n(6)*4;
    %DATA CONTAINER START 
    n(7)=saveComponent(file,'xres','i',numstepsx);
    n(8)=saveComponent(file,'yres','i',numstepsy);
    n(9)=saveComponent(file,'xreal','d',abs(endx-startx)/1E6); %µm
    n(10)=saveComponent(file,'yreal','d',abs(endy-starty)/1E6);
    n(11)=saveComponent(file,'xoff','d',startx/1E6);
    n(12)=saveComponent(file,'yoff','d',starty/1E6);
    n(13)=saveComponent(file,'si_unit_xy','o','GwySIUnit');
    n(14)=fwrite(file,sizeGwyUnitContainerxy,'uint32');
    n(14)=n(14)*4;
    %UNIT Container Start
    n(15)=saveComponent(file,'unitstr','s',xyunit);
    %UNIT Container End
    n(16)=saveComponent(file,'si_unit_z','o','GwySIUnit');
    n(17)=fwrite(file,sizeGwyUnitContainerz,'uint32');
    n(17)=n(17)*4;
    %UNIT Container Start
    n(18)=saveComponent(file,'unitstr','s',unit{i});
    %UNIT Container End
    b=reshape(data(:,:,i)',1,numpoints);
    n(20)=saveComponent(file,'data','D',b);
    %DATA CONTAINER END

    n(21)=fprintf(file,'/%u/data/title%s%c%s%s',i-1,0,'s',label{i},0);
    n(22)=fprintf(file,'/%u/meta%s%c%s%s',i-1,0,'o','GwyContainer',0);
    n(23)=fwrite(file,63,'uint32');
    n(23)=n(23)*4;
    n(24)=saveComponent(file,'Version','s','Matlab2Gwyddion 1.0');
    n(25)=saveComponent(file,'DateAcquired','s',datestr(time,'yyyy-mm-dd HH:MM:SS'));

    expectedTopContainerSize = expectedTopContainerSize + sum(n(4:end));
    i = i+1;
end


expectedDataContainerSize = sum(n(7:20));
if expectedTopContainerSize ~= sizeGwyContainer || expectedDataContainerSize ~= sizeGwyDataFieldContainer
    warning(['Real byte number is different than the expected byte number\n',...
            'Real byte number GwyContainer = %d, expected size = %d\n',...
            'Real byte number GwyDataFieldContainer = %d, expected size = %d\n'],...
            sizeGwyContainer,expectedTopContainerSize,...
            sizeGwyDataFieldContainer,expectedDataContainerSize)
end

fclose(file);


function bytes=saveComponent(file,name,type,value)
    %Write Gwy Component to file
    switch type
        case 's'
            bytes=fprintf(file,'%s%s%c%s%s',name,0,type,value,0);
        case 'i'
            bytes=fprintf(file,'%s%s%c',name,0,type);
            num=fwrite(file,value,'int32');
            bytes=bytes+num*4;
        case 'o'
            bytes=fprintf(file,'%s%s%c%s%s',name,0,type,value,0);
        case 'd'
            bytes=fprintf(file,'%s%s%c',name,0,type);
            num=fwrite(file,value,'double');
            bytes=bytes+8*num;
        case 'b'
            bytes=fprintf(file,'%s%s%c',name,0,type);
            num=fwrite(file,value,'uint8');
            bytes=bytes+num;
        case 'D'
            bytes=fprintf(file,'%s%s%c',name,0,type);
            fwrite(file,numel(value),'uint32');
            num=fwrite(file,value,'double');
            bytes=bytes+8*num+4;
    end
end

end

