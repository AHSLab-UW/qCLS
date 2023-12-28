classdef randCLS <qCLS
    
    methods
        
        function findx(qcls)
    
            freq_candidate = randi(qcls.par.Nfreqs);
            redrw_flag = 1;
            redrw_counter = 0;
            while (redrw_flag == 1) && (redrw_counter < 20)
                redrw_counter = redrw_counter + 1;
                lev_candidate = qcls.par.x_lim(1,2):5:qcls.par.x_lim(2,2);
                lev_candidate = lev_candidate(randi(length(lev_candidate)));
                
                redrw_flag = 0;
                if qcls.n >0
                    prev11 = min(qcls.x(qcls.x(:,1) == freq_candidate & qcls.r == qcls.par.Ncategories,2));
                    prev1 = max(qcls.x(qcls.x(:,1) == freq_candidate & qcls.r == 1,2));
                    if ~isempty(prev11) && lev_candidate > prev11
                        redrw_flag = 1;
                    end
                    if ~isempty(prev1) && lev_candidate < prev1
                        redrw_flag = 1;
                    end
                    
                end
            end
            qcls.xnext = [freq_candidate, lev_candidate];
        
        end

               
    end
end
%eof