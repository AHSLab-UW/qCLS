classdef qCLS_PCA_Model <handle
    
    properties
        %basic properties
        model;  % the model parameters
        Nfreqs = 10;
        freqs = [250 500 750 1000 1500 2000 3000 4000 6000 8000];
        Ncategories = 11;
        beta = .5;      % psychometric-function slope for the candidate model
        lambda = .1;    % psychometric-function lapse rate, i.e. the probability of time that the listener would generate a random response
        Ncomp; 

        % iso-loudness-level contour
        phons = 20:20:100;
        
    end
    
    methods

        % definitions for the psychometric functions and their associated jacobian
        % matrices

        % threshold (categorical boundary) contours. The categorical
        % boundaries are modeled as piece-wise interpolation curves through
        % a set number of anchor points in the level-by-freq space. The
        % number of anchor points is given by variable qcls_pca_model.kfreqs. The
        % function calc_alpha returns the model predicted 10 categorical
        % boundaries "a" at a designated frequency "freq".
        function a = calc_alpha(qcls_pca_model, freq, phi)
            
            Xnorm_pred = phi'*qcls_pca_model.model.V';
            cb_pred = Xnorm_pred.*qcls_pca_model.model.d + qcls_pca_model.model.mu;
            cb_pred = reshape(cb_pred, [], qcls_pca_model.Nfreqs);
            if rem(freq, 1) == 0
                a = cb_pred(:,freq);
            else
                fL = floor(freq);
                fH = ceil(freq);
                aL = cb_pred(:,fL);
                aH = cb_pred(:,fH);
                a = aL + (freq - fL)/(fH - fL)*(aH - aL);
            end

        end

        function ph_spl = calc_elc_spl(qcls_pca_model, alpha)
            ph_spl = zeros(length(qcls_pca_model.phons),size(alpha,2));
            NH1k = [0 18.309 33.668 48.953 63.718 75.942 82.27 87.093 91.878 96.643 110];   % loudness levels in phons for each of the categories for NH listeners at 1 kHz 
            NH1k_cu = 0:5:50;   % the loudness categories in CU for NH listeners at 1 kHz
            ph_cu = interp1(NH1k, NH1k_cu, qcls_pca_model.phons); % the loudness category in CU that corresponds to loudness levels of 20:20:100 phon

            categories_cu = linspace(0, 50, qcls_pca_model.Ncategories);  % loudness categories of the current procedure in CU
            alpha_cu = (categories_cu(1:qcls_pca_model.Ncategories-1) + categories_cu(2:qcls_pca_model.Ncategories))/2; % the categorical boundaries of the current procedure in CU
            
            nfreqs = size(alpha,2);
            for ifreq = 1:nfreqs
                ph_spl(:,ifreq) = interp1(alpha_cu, alpha(:,ifreq), ph_cu);
            end
        end

        % psychometric function
        % kfreqs: frequencies of the anchor points, identifying the
        % candidate model; phi: parameters for the candidate model; x:
        % stimulus parameters
        function p = CLS_psycfun(qcls_pca_model, x, phi)
            freq = x(:,1);
            lev = x(:,2);
            
            alpha = qcls_pca_model.calc_alpha(freq, phi);
            p_chance = (qcls_pca_model.Ncategories-1:-1:1)'/qcls_pca_model.Ncategories;
            p = qcls_pca_model.lambda*p_chance + (1-qcls_pca_model.lambda)./(1+exp(-qcls_pca_model.beta.*(lev-alpha)));
        end

        % likelihood
        function loglikelihood = calc_likelihood(qcls_pca_model, phi, x, r)
            ntrials = length(r);
            loglikelihood = 0;
            for itrial = 1:ntrials
                p = qcls_pca_model.CLS_psycfun(x(itrial,:), phi);
                n = r(itrial,:) > (1:10)';
                logL = sum(n.*log(p) + (1-n).*log(1-p));
                loglikelihood = loglikelihood + logL;
            end

        end

        % model evaluation
        function [cb_pred, elc_pred] = run_model(qcls_pca_model, s)
            % s is the component scores arrange as a vector of the size 1-by-Ncomp
            Xnorm_pred = s'*qcls_pca_model.model.V';
            cb_pred = Xnorm_pred.*qcls_pca_model.model.d + qcls_pca_model.model.mu;
            cb_pred = reshape(cb_pred, [], qcls_pca_model.Nfreqs);
            elc_pred = qcls_pca_model.calc_elc_spl(cb_pred);
        end
        
        %constructor
        function qcls_pca_model = qCLS_PCA_Model(model)
            % Model settings
            qcls_pca_model.model = model;  % the model parameters
            qcls_pca_model.Ncomp = qcls_pca_model.model.par.Ncomp;
        end  
        
    end

end

%eof