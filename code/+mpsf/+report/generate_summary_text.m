function out = generate_summary_text(data_dir)
% Generate a text summary of data in this folder.
%
% function out = generate_summary_text(data_dir)
%
% Purpose
% This function generates a text summary of the information present in this folder.
% This can be embedded into a report.
%
% Inputs
% data_dir - optional, if nothing is provided the current directory is used
%
%
% Rob Campbell - SWC 2022



if nargin<1
    data_dir = pwd;
end



% Load an image extract from it information about the microscope.
d = mpsf.report.getScanImageTifNames(data_dir);

header = sibridge.readTifHeader(fullfile(d(1).folder,d(1).name));

scanimageVersion = sprintf('%d.%d.%d', header.VERSION_MAJOR, ...
                                       header.VERSION_MINOR, ...
                                       header.VERSION_UPDATE);



% Obtain the date range over which the data were recorded
dates = {d.date};
dates = cellfun(@(tdate) regexprep(tdate,' .*',''), dates, 'UniformOutput',false);
% Sort dates
[~,ind]=sort(datenum(dates));
dates = unique(dates(ind));

% Make a string that describes when data were acquired
if length(dates)==1
    acqDate = sprintf('on %s', dates{1});
else
    acqDate = sprintf('between %s and %s', dates{1}, dates{end});
end


% Get microscope information from the settings file
mic = mpsf.settings.readSettings;


if contains(header.scannerType,'RG')
    scannerType = sprintf('Microscope is resonant scanning at %0.0f kHz. ', ...
                header.scannerFrequency/1E3);
elseif strcmp(header.scannerType,'GG')
    scannerType = sprintf('Microscope is galvo scanning. ');
else
    scannerType = '';
end


%%
% Make summary text
out = '';

if ~isempty(mic)
    if ~isempty(mic.microscope_name)
        out = [out, sprintf('Report for microscope "%s" acquired %s ', mic.microscope.name, acqDate)];
    else
        out = [out, sprintf('Microscope summary data were acquired %s ', acqDate)];
    end
end

out = [out, ...
    sprintf('using ScanImage version %s. ', scanimageVersion), ...
    scannerType];


if ~isempty(mic)
    if ~isempty(mic.imagingLasers)
        for ii=1:length(mic.imagingLasers)
            out = [out, sprintf('Laser: %s. ', mic.imaginingLasers(ii).name)];
        end
    end
    if ~isempty(mic.objective)
        out = [out, sprintf('Objective: %s. ', mic.objective.name)];
    end
end
