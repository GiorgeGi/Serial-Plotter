#! /usr/bin/octave -qf

pkg load instrument-control;

%% List all serial ports a board is connected for user to initialize connection
serial_ports = serialportlist("available");
fprintf('Available serial ports:\n');
for i = 1:length(serial_ports)
    fprintf('%d: %s\n', i, serial_ports{i});
end

fprintf("\n");

hold on;
grid on;

%% Make the plot is bit more clear
set(groot, 'defaultlinelinewidth', 2)
set(groot, 'defaultaxesxminortick', 'on')
set(groot, 'defaultaxesyminortick', 'on');
set(groot, 'defaulttextfontsize', 16); 
set(groot, "defaultaxesfontsize", 14) 


%% Connect to serial port and flush, initalize sample string
port = input('Enter board port: ', 's');
port = strtrim(port);
baudrate = input("Enter baudrate: ");
s1 = serial(port, baudrate);
% This is for testing
% s1 = serial("/dev/ttyACM0", 38400);                
srl_flush(s1);
sample = '';

% Define the way Serial.print()'s are split (either tabs "\t", spaces " " etc) depending on the code of target board
delimiter = input('Enter the signal delimiter: ', 's');

%% Read one line here to figure out how many signals there are
while true
    % Read one character at a time
    data = srl_read(s1,1);                           
    % If LF (end of Serial.println)
    if (data != 10)                                  
       sample = strcat(sample,char(data));
    else
        % Split sample based on the uploaded code to the target board, strsplit returns cellarray
        values = strsplit (sample, delimiter);            
        num_signals = size(values)(2);
        % Reset sample string
        sample = '';                                 
        break;
    endif
endwhile

% Create the x-axis vector
x = linspace (0, 1000, 1000);                       
buffSize = 1000;
% Array dimensions
sampleBuff = zeros(num_signals,buffSize); 

for i=1:num_signals
    % Initialize empty plots
    plot(nan);                                                  
endfor

% Get handle (vector of the line objects)
p = findobj(gca,'Type','line');                                 

for i=1:num_signals
    % Set the x-axis to the sample index
    set (p(i), "xdata", x);                                     
endfor

%% Clear the I/O buffers of the serial port to clear any old data and start reading 
unwind_protect
fprintf("\n");
% If an interrupt is initiated it branches to srl_close(s1);
fprintf("Interrupt process (Ctrl + C) to export data in CSV\n");
srl_flush(s1);
    while true
        % Read one character at a time
        data = srl_read(s1,1); 
        % If LF (end of Serial.println)        
        if (data != 10)                                          
           sample = strcat(sample,char(data));
        else 
            values = strsplit(sample,"\t");
            valvec = cellfun(@str2num,values,'UniformOutput',false);
            % Reset sample string
            sample = '';                                         
            sampleBuff = [cell2mat(valvec)' sampleBuff(:,1:end-1)];
            % For debugging
            % fprintf('Sample Buffer Size: %dx%d\n', size(sampleBuff));
            for i=1:num_signals
                set (p(i), "ydata", sampleBuff(i,:));
                drawnow
            endfor
        endif
    endwhile
unwind_protect_cleanup
    srl_close(s1);
    fprintf ('Caught interrupt. Save data?\n');
    choice = input('Enter "yes" to export, or any other key to skip: ', 's');
    if strcmpi(choice, 'yes')
        fprintf('Exporting data to CSV...\n');

        % Generate a unique filename with a timestamp
        filename = strcat("serialplotterdata_", datestr(now(), 'yyyymmddHHMMSS'), ".csv");

        % Save your data (assuming sampleBuff is defined somewhere in your code)
        csvwrite(filename, sampleBuff');

        fprintf('Data exported to: %s\n', filename);
    else
        fprintf('Data export skipped.\n');
    end
end