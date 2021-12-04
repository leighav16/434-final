% allison = 1 hanna = 2 iris = 3 kendra = 4 leigha = 5 megan = 6
subject = ["Allison" "Hanna" "Iris" "Kendra" "Leigha" "Megan"];
fs = 200; i = 1;

% Calculate each person's average heart rate one by one
for i = 1:6
    fprintf("%s \n", subject(i));
    
    % load .mat as struct into memory
    inputFile = "%d.mat";
    raw = load(sprintf(inputFile,i));

    % separate out each data section
    control = raw.data(raw.datastart(1):raw.dataend(1));    % taken before experiment
    trial   = raw.data(raw.datastart(2):raw.dataend(2));    % taken during experiment
    after   = raw.data(raw.datastart(3):raw.dataend(3));    % taken after  experiment

    figure(i);
    % Plot the control data
    subplot(3,1,1);
    t = linspace(0,(1/fs)*length(control),length(control));
    plot(t,control);
    title("Baseline / control ECG for " + subject(i));
    xlabel("t (seconds)"); ylabel("mV");
    xlim([0 length(control)*1/fs]); ylim([-0.5E-3 0.75E-3]);

    % Plot the trial data
    subplot(3,1,2);
    t = linspace(0,(1/fs)*length(trial),length(trial));
    plot(t,trial);
    title("Trial ECG for " + subject(i));
    xlabel("t (seconds)"); ylabel("mV");
    xlim([0 length(trial)*1/fs]); ylim([-0.5E-3 0.75E-3]);

    % Plot the after data
    subplot(3,1,3);
    t = linspace(0,(1/fs)*length(after),length(after));
    plot(t,after);
    title("After trial ECG for " + subject(i));
    xlabel("t (seconds)"); ylabel("mV");
    xlim([0 length(after)*1/fs]); ylim([-0.5E-3 0.75E-3]);

    % Get the location of each QRS peak
    [Q,R,S] = qrs(control,fs);
    % calculate average heart rate
    [hr_ave_control] = hr(R,fs);
    % For error checking.  If the number of Q, R, and S peaks detected is
    % significantly different, we may want to manually count that section.
    fprintf("CONTROL: num Q: %d, num R: %d, num S: %d\n",length(Q), length(R), length(S));

    [Q,R,S] = qrs(trial,fs);
    [hr_ave_trial] = hr(R,fs);
    fprintf("TRIAL: num Q: %d, num R: %d, num S: %d\n",length(Q), length(R), length(S));

    [Q,R,S] = qrs(after,fs);
    [hr_ave_after] = hr(R,fs);
    fprintf("AFTER: num Q: %d, num R: %d, num S: %d\n",length(Q), length(R), length(S));

    fprintf("Control: %.02f, Trial: %.02f, After: %.02f. \n", hr_ave_control, hr_ave_trial, hr_ave_after);

end


% FIND QRS PEAKS
function [Q,R,S] = qrs(unfiltered_data,fs)
    % filter the data with a 8 - 20 Hz bandpass filter
    filtered_data = bandpass(unfiltered_data,[8 20],fs);
    
    % now use threshold method to find QRS peaks
    % find the R peak             % find Q and S peak
    maximum = max(filtered_data); minimum = min(filtered_data);

    Q_ele = 1;  last_i_Q = -70;
    R_ele = 1;  last_i_R = -70;
    S_ele = 1;  last_i_S = -70;

    for i = 1:length(filtered_data)
       if(filtered_data(i) > (0.4 * maximum))
           % implement resting period after finding a peak
           if((i - last_i_R) > 60)
               R(R_ele) = i;  
               R_ele = R_ele + 1;
               last_i_R = i;
           end
       end    
      if(filtered_data(i) < (0.4 * minimum))
      % implement resting period after finding a peak
        if((i - last_i_Q) > 90)
            Q(Q_ele) = i;  
            Q_ele = Q_ele + 1;
            last_i_Q = i;
        end
        if(((i - last_i_Q) > 10) && ((i - last_i_S) > 90))
            S(S_ele) = i;  
            S_ele = S_ele + 1;
            last_i_S = i;
        end    
      end 

    end
end    

% CALCULATE AVERAGE HEART RATE
function [hr_ave] = hr(R,fs)
    l = length(R);
    % calculate heart rate
    for i = 1:l-1
       hr_period(i) = (R(i + 1) - R(i)) * (1/fs); 
    end    

    hr_freq = (1 ./ hr_period) * 60;
    hr_ave = mean(hr_freq);

end