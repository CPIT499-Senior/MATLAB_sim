% utm2deg.m
% Converts UTM coordinates to latitude and longitude
% Source: Open implementation

function [lat, lon] = utm2deg(x, y, zone)
    if ischar(zone)
        zone = str2double(zone);
    end

    sa = 6378137.000000; sb = 6356752.314245;
    e2 = ((sa^2 - sb^2) ^ 0.5) / sb;
    e2cuadrada = e2^2;
    c = (sa^2) / sb;
    x = x - 500000;
    x = x / 0.9996;
    y = y / 0.9996;
    S = ((zone * 6) - 183);
    lat = y / (6366197.724 * 0.9996);
    v = c / sqrt(1 + (e2cuadrada * (cos(lat))^2));
    a = x / v;
    a1 = sin(2 * lat);
    a2 = a1 * (cos(lat))^2;
    j2 = lat + ((a1 / 2));
    j4 = ((3 * j2) + a2) / 4;
    j6 = ((5 * j4) + (a2 * (cos(lat))^2)) / 3;
    alfa = (3 / 4) * e2cuadrada;
    beta = (5 / 3) * alfa^2;
    gama = (35 / 27) * alfa^3;
    Bm = 0.9996 * c * (lat - alfa * j2 + beta * j4 - gama * j6);
    b = (y - Bm) / v;
    Epsi = ((e2cuadrada * a^2) / 2) * (cos(lat))^2;
    Eps = a * (1 - (Epsi / 3));
    nab = b * (1 - Epsi + (Epsi^2));
    lon = S + (Eps * (180 / pi));
    lat = lat - ((nab * (180 / pi)));

    % Clamp output if needed
    lat = max(min(lat, 90), -90);
    lon = mod((lon + 180), 360) - 180;
end

% The code below requires a mapping toolbox
%function [Lat, Lon] = utm2deg(x, y, zone)
% Convert UTM to Lat/Lon. Assumes WGS84
%utmstruct = defaultm('utm');
%utmstruct.zone = zone;
%utmstruct.geoid = wgs84Ellipsoid;
%utmstruct = defaultm(utmstruct);
%[Lat, Lon] = minvtran(utmstruct, x, y);
%end

