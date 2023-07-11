function Schaefervolumecombined = importfile(filename, dataLines)
%IMPORTFILE Import data from a text file
%  SCHAEFERVOLUMECOMBINED = IMPORTFILE(FILENAME) reads data from text
%  file FILENAME for the default selection.  Returns the data as a table.
%
%  SCHAEFERVOLUMECOMBINED = IMPORTFILE(FILE, DATALINES) reads data for
%  the specified row interval(s) of text file FILENAME. Specify
%  DATALINES as a positive scalar integer or a N-by-2 array of positive
%  scalar integers for dis-contiguous row intervals.
%
%  Example:
%  Schaefervolumecombined = importfile("/Volumes/LASA/TBI_OpenNeuro/TBI_openneuro/data/lesions/overlap_Schaefer/Schaefer100_wotbi09/Schaefer_volume_combined.csv", [1, Inf]);
%
%  See also READTABLE.
%
% Auto-generated by MATLAB on 14-Jun-2023 18:15:19

%% Input handling

% If dataLines is not specified, define defaults
if nargin < 2
    dataLines = [1, Inf];
end

%% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 2, "Encoding", "UTF-8");

% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = ";";

% Specify column names and types
opts.VariableNames = ["VarName1", "VarName2"];
opts.VariableTypes = ["double", "string"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, "VarName2", "WhitespaceRule", "preserve");
opts = setvaropts(opts, "VarName2", "EmptyFieldRule", "auto");

% Import the data
Schaefervolumecombined = readtable(filename, opts);

end