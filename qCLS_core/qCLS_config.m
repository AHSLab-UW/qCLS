function par = qCLS_config()

    % Model settings
    par.Ncategories = 11;   % the number of response categories
    par.Nfreqs = 9;    % the number of frequency bands
    par.kfreqs = 4;     % subset of candidate sites for as anchor points for models
    par.beta = .5;      % psychometric-function slope for the candidate model
    par.lambda = .1;    % psychometric-function lapse rate, i.e. the probability of time that the listener would generate a random response
    
    % the piece-wise linear model of loudness growth, assuming the same
    % prior for all frequencies, independence among frequencies. The
    % function parameters are the levels in dB SPL associated with the lowest,
    % middle, and top response categories.
    par.phi_prior_mu = [repmat([40, 90, 110],par.Nfreqs,1)];   %the means of the posterior parameter distribution
    par.phi_prior_std = [10, 10, 10];   %the standard deviations of the posterior parameter distribution
    
    % stimulus parameter
    par.x_lim = [1, 0 ; par.Nfreqs, 110];    % the two columns are for frequency index and level
    par.Lclearance = 0.1;
    par.fclearance = 0.1;
    
    par.likelihood_exp = 0.95; % for likelihood update
    par.diffusion = 0.01;  % diffusion factor for Kalman filtering
end