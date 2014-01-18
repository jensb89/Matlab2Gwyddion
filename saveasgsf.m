function saveasgsf(filename,data,numstepsx,numstepsy,startx,endx,starty,endy,label,unit,time,varargin)
%saveasgsf Save NxM matrix from SPM/AFM Scan in Gwyddion Simple Field file
%format.
%   Save data (NxM matrix) for Gwyddion (SPM (scanning probe microscopy)
%   data visualization and analysis)
%   More information about Gwyddion and the Gwyddion simple field file 
%   format can be found under http://gwyddion.net and
%   http://gwyddion.net/documentation/user-guide-en/gsf.html
%   
%   Inputs:
%   -filename
%   -data as a NXM Matrix with 
%   N = #ypoints
%   M = #xpoints
%   - startx : Startpoint for x-Axis in µm (e.g. 3.2 for 3.2µm)
%   - numstepsx : Number of Points in x-direction
%   - numstepsy
%   - endx
%   - starty
%   - endy
%   - label : string with a title (e.g. 'Chan1'}
%   - Unit : string with the SI-Unit for the data points (eg. 'V')
%   - time : actual Date+Time for metadata as serial date number (see 'now'
%   or 'datenum' for mor information about serial date numbers)
%   - extra Metadata information (cell array) // not used at the moment //
%   
%   everything after numstepsy is optional!
%
%   Example call:
%   saveasgsf('test.gsf',rand(30,200),200,30,1,2,3,4,'Chan1','V',now);
%   saveasgsf('test.gsf',rand(30,200),200,30);
%
%   Version 1.0
%
%   Copyright (C) Jens Brauer, www.jens-brauer.de, 2014

file = fopen(filename,'w','l'); 

nbytes(1)=fprintf(file,'Gwyddion Simple Field 1.0\x0A');
nbytes(2)=fprintf(file,'XRes = %d\x0A',numstepsx);
nbytes(3)=fprintf(file,'YRes = %d\x0A',numstepsy);
if nargin > 4
    nbytes(4)=fprintf(file,'XReal = %f\x0A',abs(endx-startx)/1E6); %µm
    nbytes(5)=fprintf(file,'YReal = %f\x0A',abs(endy-starty)/1E6);
    nbytes(6)=fprintf(file,'XOffset = %f\x0A',startx/1E6);
    nbytes(7)=fprintf(file,'YOffset = %f\x0A',starty/1E6);
end
nbytes(8)=fprintf(file,'XYUnits = m\x0A');
if exist('unit','var')
    nbytes(9)=fprintf(file,'ZUnits = %s\x0A',unit);
end
if exist('label','var')
    nbytes(10)=fprintf(file,'Title = %s\x0A',label);
end
nbytes(11)=fprintf(file,'Version = Matlab2Gwyddion 1.0\x0A');
if exist('time','var') 
    nbytes(12)=fprintf(file,'Date=%s\x0A',datestr(time,'yyyy-mm-dd HH:MM:SS'));
end

N=sum(nbytes);

switch mod(N,4)
    case 0
        fprintf(file,'%s%s%s%s',0,0,0,0); % %s string conversion to integer values (ex. %s,65 = A etc. 0=NUL)
    case 1
        fprintf(file,'%s%s%s',0,0,0);
    case 2
        fprintf(file,'%s%s',0,0);
    case 3
        fprintf(file,'%s',0);
end

fwrite(file,data,'float32',0,'l');%Little-endian ordering, 32-bit long data type

fclose(file);
end

