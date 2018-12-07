%function source
%input : settings
%output : signal_original
%function : generate the signal with noise;
function signal_original = source_ (settings)

noise = settings.noise_std*rand(1,settings.Ncoh);
signal_amplitude = sqrt(10^(settings.snr/10)*(settings.noise_std^2*2));
signal_original = signal_amplitude*cos(2*pi*(settings.middle_freq  + settings.dup_freq )*settings.dot_length*settings.sample_t) + noise;