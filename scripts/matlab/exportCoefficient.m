% This script exports coefficients from the msa-toolkit library into a
% binary file that godot can read
%
% msa-toolkit link: https://git.skywarder.eu/afd/msa/msa-toolkit
%
% coefficients depend on alpha, mach, phi, abk extension
%
% binary is stored in the following format:
%   - ID,     char[4],  file identifier
%   - DIMS,   uint8[4], dimension sizes NALPHA, NMACH, ...
%
%   - ALPHA,  single[NALPHA]
%   - MACH,   single[NMACH]
%   - PHI,    single[NPHI]
%   - ABK,    single[NABK]
%
%   - L       single[1], reference length (rocket diameter)
%   - XCG     single[1], reference xcg
% 
%   - COEFFS, single[6, NALPHA * NMACH * NPHI * NABK]
%
%   NOTE: the six coefficients are [CA, CY, CN, Cl, Cm, Cn], i.e. forces on
%         [x y z] and moments along [x y z] axes.
%         Check help of Coefficient class in msa toolkit for more info

workingDir = fileparts(mfilename("fullpath"));

coeffID = 'AERO'; % Just to check the correct file type is loaded
coeffFile = fopen( ...
    fullfile(workingDir, 'coefficients.bin'), ...
    'wb');

% NOTE: check that msa-toolkit has been added to path
currentMission = Mission(true, 'changeMatlabPath', true);
dataPath = fullfile(currentMission.dataPath, 'aeroCoefficients.mat');
coeffs = Coefficient(dataPath);

% Reading metadata and converting into SI units
alpha = single(coeffs.state.alphas * pi/180);
mach = single(coeffs.state.machs);
phi = single(coeffs.state.phis * pi/180);
abk = single(coeffs.state.hprot / coeffs.state.hprot(end)); % Normalize on max extension

nalpha = uint8(length(alpha));
nmach = uint8(length(mach));
nphi = uint8(length(phi));
nabk = uint8(length(abk));

% Reading reference geometry
l = single(coeffs.geometry.diameter);
xcg = single(coeffs.geometry.xcg);

% Importing only initial altitude
data = single(squeeze(coeffs.static(:, :, :, :, 1, :, 1)));

fwrite(coeffFile, coeffID, 'char');
fwrite(coeffFile, [nalpha, nmach, nphi, nabk], 'uint8');
fwrite(coeffFile, [alpha, mach, phi, abk], 'single');
fwrite(coeffFile, [l, xcg], 'single');
fwrite(coeffFile, data, 'single');
fclose(coeffFile);