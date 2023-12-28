function [x,t,SPL_Correction]=StimGenerator(Type,Dur,Freq,BW,sr)

ramp_on=200; % onset and offset time for time-domain window in milliseconds

Dur=Dur./1000;
nt=Dur*sr;
t=(0:nt-1)'./sr;

EarTone3A_Freq = [250 500 750 1000 1500 2000 3000 4000 6000 8000];
% EarTone3A_SPL_Correction = [2.7 1.9 1.8 0.2 -1.0 -0.7 0.1 3.9 20.4 29.6];       % calibration from the published specs, digitized by Steve
EarTone3A_SPL_Correction = [2.7-4.5 1.9-3 1.8-1.5 0.2-2 -1.0-0.5 -0.7 0.1 3.9-1.5 20.4-2 29.6+4];         % calibration Shen Lab 08292023

% EarTone3A_Freq=[500 750 1000 1500 2000 3000 4000];
% EarTone3A_SPL_Correction=80.5-[78.8 80.1 80.5 80.4 80.0 77.2 70.6];

if strcmp(Type,'noise')% Bandpass noise
    % rng(1);

    % calculate the two cutoff frequencies based on the center frequency
    % "Freq" and the bandwidth "BW", both in Hz
    fL = (sqrt(BW^2 + 4*Freq^2) - BW)/2;
    fH = (sqrt(BW^2 + 4*Freq^2) + BW)/2;

    % generate a bandpass noise in the frequency domain using fft

    xfft = zeros(size(t));
    f = (0:nt-1)/nt*sr;
    f_idx = find(f>=fL & f<=fH);
    nf = length(f_idx);
    f_mag = sqrt(randn(nf,1).^2 + randn(nf, 1).^2);
    f_ph = 2*pi*rand(nf,1);
    xfft(f_idx) = f_mag.*exp(1j*f_ph);
    x = ifft(xfft,'symmetric');
elseif strcmp(Type,'tone') % Pure tone
    x=cos(2*pi*Freq.*t);     
end
x = x/rms(x);
SPL_Correction = interp1(log2(EarTone3A_Freq), EarTone3A_SPL_Correction, log2(Freq));
x=ramp(x,ramp_on,sr);

end

function y=ramp(x,rt,sr)
% creates smooth onset and offset
% x  - signal
% rt - onset time in ms
    % sr - sampling rate
    rt=rt/1000;
    n1=ceil(2*sr*rt);
    w1=tukeywin(n1);
    n2=ceil(length(w1)/2);
    w2=w1(1:n2);
    w3=flipud(w2);
    n3=length(x)-2*length(w2);
    w=[w2;ones(n3,1);w3];
    y=x.*w;
end
%
