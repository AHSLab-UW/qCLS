classdef entropyCLS <qCLS
    
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
            x_candidate = [freq_candidate, lev_candidate];
            
            % after 10 trials, active optimization starts. The optimization
            % is based on minimizing the expected entropy
            if qcls.n > 50
                xnext = fminsearch(@(x) calc_entropy(qcls, x) + (x(1)<1 || x(1)>qcls.par.Nfreqs)*1e3, x_candidate, optimset('MaxIter',10,'Display','off'));
                if xnext(1) > qcls.par.x_lim(2,1) || xnext(1) < qcls.par.x_lim(1,1) || xnext(2) > qcls.par.x_lim(2,2) || xnext(2) < qcls.par.x_lim(1,2)
                    xnext = x_candidate;
                end
            else
                xnext = x_candidate;
            end
            qcls.xnext = xnext;
        end

        function entropy = calc_entropy(qcls, x)
            entropy = 0;
            L = exp(qcls.Lmodels-max(qcls.Lmodels));
            L = L/sum(L);
            for imodel = 1:length(qcls.models)
                if L(imodel) > 1e-2
                    [~, P1, ~] = qcls.Kalman_update(qcls.models(imodel).phi, qcls.models(imodel).P,...
                        qcls.models(imodel).kfreqs, x, ones(qcls.par.Ncategories-1,1));
                    Hexp = log(det(P1));
                    entropy = entropy + L(imodel)*Hexp;
                end
            end
        end
               
    end
end
%eof