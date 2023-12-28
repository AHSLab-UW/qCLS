classdef qCLS <handle
    
    properties
        %basic properties
        x    % stimulus parameter
        xnext % the next stimulus based on the previous data;
        Lmodels % likelihood of various models
        models % model struct
        r   %the listener's responses (correctness)
        par %the data structure containing the configurations of the parameter space   
        n=0;   %the trial number

        % iso-loudness-level contour
        phons = 20:20:100;
        % phons = 20:20:80;
        
        % variable names reserved for user defined data
        userdata01
        userdata02
        userdata03
        userdata04
    end
    
    methods

        % definitions for the psychometric functions and their associated jacobian
        % matrices

        % threshold (categorical boundary) contours. The categorical
        % boundaries are modeled as piece-wise interpolation curves through
        % a set number of anchor points in the level-by-freq space. The
        % number of anchor points is given by variable qcls.kfreqs. The
        % function calc_alpha returns the model predicted 10 categorical
        % boundaries "a" at a designated frequency "freq".
        function a = calc_alpha(qcls, freq, kfreqs, phi)
            Nfreqs = length(freq);
            a = zeros(qcls.par.Ncategories-1, Nfreqs);
            alpha_tmp = zeros(qcls.par.Ncategories-1, size(qcls.par.kfreqs,2));
            for ianchor = 1:qcls.par.kfreqs
                alpha_tmp(:, ianchor) = pchip([1, qcls.par.Ncategories/2, qcls.par.Ncategories-1],phi((ianchor-1)*3+1:ianchor*3), 1:qcls.par.Ncategories-1);
            end
            for ifreq = 1:Nfreqs
                a(:,ifreq) = pchip(kfreqs,alpha_tmp,freq(ifreq));
            end
        end

        function ph_spl = calc_ph_spl(qcls, alpha)
            ph_spl = zeros(length(qcls.phons),size(alpha,2));
            NH1k = [0 18.309 33.668 48.953 63.718 75.942 82.27 87.093 91.878 96.643 110];   % loudness levels in phons for each of the categories for NH listeners at 1 kHz 
            NH1k_cu = 0:5:50;   % the loudness categories in CU for NH listeners at 1 kHz
            ph_cu = interp1(NH1k, NH1k_cu, qcls.phons); % the loudness category in CU that corresponds to loudness levels of 20:20:100 phon

            categories_cu = linspace(0, 50, qcls.par.Ncategories);  % loudness categories of the current procedure in CU
            alpha_cu = (categories_cu(1:qcls.par.Ncategories-1) + categories_cu(2:qcls.par.Ncategories))/2; % the categorical boundaries of the current procedure in CU
            
            Nfreqs = size(alpha,2);
            for ifreq = 1:Nfreqs
                ph_spl(:,ifreq) = interp1(alpha_cu, alpha(:,ifreq), ph_cu);
            end
        end

        % psychometric function
        % kfreqs: frequencies of the anchor points, identifying the
        % candidate model; phi: parameters for the candidate model; x:
        % stimulus parameters
        function p = CLS_psycfun(qcls, x, kfreqs, phi)
            freq = x(:,1);
            lev = x(:,2);
            
            alpha = qcls.calc_alpha(freq, kfreqs, phi);
            p_chance = (qcls.par.Ncategories-1:-1:1)'/qcls.par.Ncategories;
            p = qcls.par.lambda*p_chance + (1-qcls.par.lambda)./(1+exp(-qcls.par.beta.*(lev-alpha)));
        end
        
        % Jacobian
        % kfreqs: frequencies of the anchor points, identifying the
        % candidate model; phi: parameters for the candidate model; x:
        % stimulus parameters
        function H = CLS_jacobian(qcls, x, kfreqs, phi)
            % all derivative here are calculated numerically
            % model parameters in phi
            h = 1e-3;   % this determines the local truncation error
        
            % 1-point numerical derivative (less accurate but fast)
            % ref
            ref =qcls.CLS_psycfun(x, kfreqs, phi);
            H = zeros(qcls.par.Ncategories-1,length(phi));
            for iphi = 1:length(phi)
                phi_tmp = phi;
                phi_tmp(iphi) = phi_tmp(iphi) + h;
                H(:,iphi) = (qcls.CLS_psycfun(x, kfreqs, phi_tmp)-ref)/h;
            end
        end

        %constructor
        function qcls = qCLS(par)
            qcls.par = par;
            reset(qcls);
        end  
        
        % INITIALIZATION
        function reset(qcls)
            qcls.x;
            qcls.r;
            qcls.n = 0;
            
            % prior distributions
            xn = nchoosek(2:qcls.par.Nfreqs-1, qcls.par.kfreqs-2);
            xn = [ones(size(xn,1),1) xn qcls.par.Nfreqs*ones(size(xn,1),1)];
            qcls.Lmodels = zeros(size(xn,1),1);    % likelihood of various models
            for imodel = 1:length(qcls.Lmodels)
                qcls.models(imodel).kfreqs = xn(imodel,:)';
%                 qcls.models(imodel).phi = repmat(qcls.par.phi_prior_mu, 1, qcls.par.kfreqs)';         %the mean of the posterior parameter distribution
                qcls.models(imodel).phi = reshape(qcls.par.phi_prior_mu(xn(imodel,:),:)',[],1);
                qcls.models(imodel).P = diag(repmat(qcls.par.phi_prior_std, 1, qcls.par.kfreqs).^2); %the covariance matrix of the posterior parameter distribution
            end

            % find the stimulus for the first trial
            findx(qcls);
        end
        
        % ITERATION
        
        %Update posterior and xnext based on the previous posterior and the
        %new response r.
        function update(qcls, r , x)
            qcls.n = qcls.n + 1;
            qcls.r(qcls.n,:) = r;
            if nargin == 2
                qcls.x(qcls.n,:) = qcls.xnext;
            elseif nargin == 3
                qcls.x(qcls.n,:) = x;
            end
            
            % update model parameters
            for imodel = 1:length(qcls.Lmodels)
                r_tmp = qcls.r(qcls.n,:) > (1:qcls.par.Ncategories-1)';
                [qcls.models(imodel).phi, qcls.models(imodel).P, l] = ...
                    qcls.Kalman_update(qcls.models(imodel).phi, qcls.models(imodel).P, ...
                    qcls.models(imodel).kfreqs, qcls.x(qcls.n,:), r_tmp);
                qcls.Lmodels(imodel) = qcls.par.likelihood_exp*qcls.Lmodels(imodel)+sum(log(l));    % update the likelihood
            end
                
            %Find the next signal strength
            findx(qcls);
        end

        %Stimulus selection
        function findx(qcls)
            
            freq_candidate = randi(qcls.par.Nfreqs);
            lev_candidate = qcls.par.x_lim(1,2):5:qcls.par.x_lim(2,2);
            lev_candidate = lev_candidate(randi(length(lev_candidate)));
            qcls.xnext = [freq_candidate, lev_candidate];
        end

        % functions for extended kalman filtering. Kalman filtering is used
        % for model updates after each trial.
        
        function [phi, P, l] = Kalman_update(qcls, phi, P, kfreqs, x, r)
            
%             % inherent noise source for the random-walk of the parameters
            Q = qcls.par.diffusion*diag(diag(P));
            P = P+Q;
        
            % Expected response and response variability
            mu = CLS_psycfun(qcls, x, kfreqs, phi);
            var = diag(mu.*(1-mu));
            
            % Compute Kalman gain factor:
            H1 = CLS_jacobian(qcls, x, kfreqs, phi);
            K = (P*H1')/(H1*P*H1' + var);
        
            % Correction based on observation:
            phi = phi + K*(r-mu);
            P = P - K*H1*P;
            
            % liklihood
            l = zeros(size(mu));
            l(r == 1) = mu(r == 1);
            l(r == 0) = 1 - mu(r == 0);
        end

    end

    methods(Static)

        % UTILITIES
        function xrnd = draw_rnd(lims, eta) 
            xrnd = lims(1)-(lims(2)-lims(1))*eta+(lims(2)-lims(1))*(1+2*eta)*rand;
        end

    end
end

%eof