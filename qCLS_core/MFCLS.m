classdef MFCLS <qCLS
    
    methods
        
        function findx(qcls)
            
            % find the model with the maximum likelihood
            [~,idx] = max(qcls.Lmodels);
            
            % randomly draw a candidate frequency
            freq_candidate = qcls.draw_rnd(qcls.par.x_lim(:,1), qcls.par.fclearance);
            freq_candidate = max(min(freq_candidate, qcls.par.x_lim(2,1)), qcls.par.x_lim(1,1));

            % at the candidate frequency, look up the categorical
            % boundaries from the model with the maximum likelihood
            a = qcls.calc_alpha(freq_candidate, qcls.models(idx).kfreqs, qcls.models(idx).phi);

            % randomly draw a candidate level between the lowest and
            % highest categorical boundaries.
            lev_candidate = qcls.draw_rnd([min(a), max(a)], qcls.par.Lclearance);
            lev_candidate = max(min(lev_candidate, qcls.par.x_lim(2,2)), qcls.par.x_lim(1,2));
            
            qcls.xnext = [freq_candidate, lev_candidate];
        
        end

               
    end
end
%eof