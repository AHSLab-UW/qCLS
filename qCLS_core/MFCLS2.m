classdef MFCLS2 <qCLS
    
    methods
        
        function findx(qcls)
            
            % find the model with the maximum likelihood
            [~,idx] = max(qcls.Lmodels);
            
            % randomly draw a candidate frequency
            % freq_candidate = qcls.draw_rnd(qcls.par.x_lim(:,1), qcls.par.fclearance);
            % freq_candidate = max(min(freq_candidate, qcls.par.x_lim(2,1)), qcls.par.x_lim(1,1));
            freq_candidate = randi(qcls.par.Nfreqs);

            % at the candidate frequency, look up the categorical
            % boundaries from the model with the maximum likelihood
            a = qcls.calc_alpha(freq_candidate, qcls.models(idx).kfreqs, qcls.models(idx).phi);
            
%             % method1: randomly draw a candidate level from one of the
%             % categorical boundaries.
%             a = a(randperm(qcls.par.Ncategories-1));
%             lev_candidate = a(1);

%             % method 2: sample level randomly from a lower, a higher, and 
%             % the middle categorical boundaries with equal probablility
%             % (not good).
%             a = sort(a);
%             lev_candidate = [a(3), a(3), a(qcls.par.Ncategories-3), a(qcls.par.Ncategories-3), a(floor(qcls.par.Ncategories/2)), a(ceil(qcls.par.Ncategories/2))];
%             lev_candidate = lev_candidate(randi(length(lev_candidate)));

%             % method 3: randomly draw a candidate level between a lower and
%             % a higher categorical boundaires.
%             a = sort(a);
%             lev_candidate = qcls.draw_rnd([a(2), a(qcls.par.Ncategories-2)], qcls.par.Lclearance);

            % method 4: randomly draw an estimated level at one of the
            % equal-loudness-level contours from 20:20:100 phons
            ph_spl = qcls.calc_ph_spl(a);
            lev_candidate = ph_spl(randi(length(ph_spl)));

            lev_candidate = max(min(lev_candidate, qcls.par.x_lim(2,2)), qcls.par.x_lim(1,2));
            
            qcls.xnext = [freq_candidate, lev_candidate];
        
        end

               
    end
end
%eof