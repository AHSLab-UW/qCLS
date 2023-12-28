classdef dynamic_range <handle
    
    properties
        %basic properties
        x    % stimulus parameter
        xnext % the next stimulus based on the previous data;
        next_track  % which one of the interleaved track is next;
        r   %the listener's responses   
        n=0;   %the trial number
        
        x_lim = [0 110];
        test_stage = 1;
        starting_lev = 60;
        xnext1
        track1_done
        xnext2
        xlast2
        track2_done
    end
    
    methods

        %constructor
        function dr = dynamic_range()
            reset(dr);
        end  
        
        % INITIALIZATION
        function reset(dr)
            dr.x;
            dr.r;
            dr.n = 0;
            dr.xnext = dr.starting_lev;
            dr.next_track = 0;
            dr.track1_done = 0;
            dr.track2_done = 0;
        end
        
        % ITERATION
        
        %Update xnext based on new response r.
        function update(dr, r) 
            dr.n = dr.n + 1;
            dr.x(dr.n,:) = dr.xnext;
            dr.r(dr.n,:) = r;
            
            % stage 1: make sure that the initial level is within the range
            if dr.test_stage == 1
                if r == 1
                    dr.xnext=dr.limiter(dr.xnext + 15, dr.x_lim);
                elseif r == 11
                    dr.xnext=dr.limiter(dr.xnext - 15, dr.x_lim);
                else
                    dr.test_stage = dr.test_stage + 1;
                    dr.xnext1 = dr.xnext;
                    dr.xnext2 = dr.xnext;
                    dr.xlast2 = dr.xnext;
                end
            end

            % stage 2: two interleaved tracks to estimate the limits of the
            % dynamic range
            if dr.test_stage == 2
                if dr.next_track == 1  % track 1: upper end L50
                    if dr.track1_done ~= 1
                        if r == 11 || dr.xnext1 == dr.x_lim(2)    % if "Too Loud" is collected, we are already at the upper bound, the upper limit of the stimulus space is 5 dB lower from the current level
                            dr.xnext1 = dr.xnext1 - 5;
                            dr.track1_done = 1;
                        elseif dr.xnext1 <=80       % difference step size for level increments depending on whether the current level is below of above 80 dB SPL
                            dr.xnext1=dr.limiter(dr.xnext1 + 10, dr.x_lim);
                        else
                            dr.xnext1=dr.limiter(dr.xnext1 + 5, dr.x_lim);
                        end
                    end

                    if dr.track2_done ~=1
                        dr.xnext = dr.xnext2;       % update the stimulus on the next trial
                        dr.next_track = 2;      % alternate to the other track
                    elseif dr.track1_done ~=1
                        dr.xnext = dr.xnext1;       % update the stimulus on the next trial
                        dr.next_track = 1;      % stay if the other track is done
                    else
                        dr.test_stage = dr.test_stage + 1;  % bump out if both tracks are done.
                        dr.xnext = [];
                        dr.next_track = [];
                    end
                        
                elseif dr.next_track == 2 % track 2: lower end L5
                    if dr.track2_done ~= 1
                        if r > 1 && (dr.xnext2 > dr.xlast2 || dr.xnext2 == dr.x_lim(1))
                            dr.track2_done = 1;                             % track 2 done when the first 
                        elseif r == 1
                            dr.xlast2 = dr.xnext2;
                            dr.xnext2=dr.limiter(dr.xnext2 + 5, dr.x_lim);     % Step up in 5-dB steps when an r=1 response is collected.
                        else
                            dr.xlast2 = dr.xnext2;
                            dr.xnext2=dr.limiter(dr.xnext2 - 15, dr.x_lim);    % keep stepping down in 15-dB steps until a r=1 response is obtained.
                        end
                    end

                    if dr.track1_done ~= 1
                        dr.xnext = dr.xnext1;       % update the stimulus on the next trial
                        dr.next_track = 1;      % alternate to the other track
                    elseif dr.track2_done ~=1
                        dr.xnext = dr.xnext2;       % update the stimulus on the next trial
                        dr.next_track = 2;  
                    else
                        dr.test_stage = dr.test_stage + 1;  % bump out if both tracks are done.
                        dr.xnext = [];
                        dr.next_track = [];
                    end
                elseif dr.next_track == 0   % the first trial
                    if dr.track1_done ~= 1
                        if r == 11 || dr.xnext1 == dr.x_lim(2)    % if "Too Loud" is collected, we are already at the upper bound, the upper limit of the stimulus space is 5 dB lower from the current level
                            dr.xnext1 = dr.xnext1 - 5;
                            dr.track1_done = 1;
                        elseif dr.xnext1 <=80       % difference step size for level increments depending on whether the current level is below of above 80 dB SPL
                            dr.xnext1=dr.limiter(dr.xnext1 + 10, dr.x_lim);
                        else
                            dr.xnext1=dr.limiter(dr.xnext1 + 5, dr.x_lim);
                        end
                    end
                    if dr.track2_done ~= 1
                        if r > 1 && (dr.xnext2 > dr.xlast2 || dr.xnext2 == dr.x_lim(1))
                            dr.track2_done = 1;                             % track 2 done when the first 
                        elseif r == 1
                            dr.xlast2 = dr.xnext2;
                            dr.xnext2=dr.limiter(dr.xnext2 + 5, dr.x_lim);     % Step up in 5-dB steps when an r=1 response is collected.
                        else
                            dr.xlast2 = dr.xnext2;
                            dr.xnext2=dr.limiter(dr.xnext2 - 15, dr.x_lim);    % keep stepping down in 15-dB steps until a r=1 response is obtained.
                        end
                    end

                    if dr.track1_done ~= 1
                        dr.xnext = dr.xnext1;       % update the stimulus on the next trial
                        dr.next_track = 1;      % alternate to the other track
                    elseif dr.track2_done ~=1
                        dr.xnext = dr.xnext2;       % update the stimulus on the next trial
                        dr.next_track = 2;  
                    else
                        dr.test_stage = dr.test_stage + 1;  % bump out if both tracks are done.
                        dr.xnext = [];
                        dr.next_track = [];
                    end

                end

            end
            
        end

        function doneflag = isDone(dr)
            if dr.track1_done == 1 && dr.track2_done == 1
                doneflag = 1;
            else
                doneflag = 0;
            end
        end

        function x_lim = getDR(dr)
            x_lim = [dr.xnext2 dr.xnext1];
        end
    end

    methods(Static)

        % UTILITIES
        function y = limiter(x, x_lim) 
            y = min(max(x,x_lim(1)),x_lim(2));
        end

    end


end

%eof