%%% A serial plotter tool with two modes made to test and plot sensor values from microcontrollers
%%% In reader mode it reads a .csv file data, prints them and plots a graph.
%%% In scanner mode a port scan is initiated to list the ones with connected microcontrollers
%%% The serial port, baudrate and data delimiter are required
%%% The delimiter must be the same with the microcontroller's 
%%% Any delimiter aside "\t" produces unexpected results while plotting the data


#! /usr/bin/octave -qf

pkg load instrument-control;

choice = input('Select Reader (1) or Scanner (2) mode: ');

switch choice
    case 1
        % Get a list of .csv files in the current directory
        csvFiles = dir('*.csv');

        % Check if any .csv files were found
        if ~isempty(csvFiles)
            fprintf('CSV files found in the current directory:\n');
    
        % Iterate through the structure array and print file names
            for i = 1:numel(csvFiles)
                fprintf('%d: %s\n', i, csvFiles(i).name);
            end
        else
            fprintf('No CSV files found in the current directory.\n');
            % No reason to inputing file name when non exist in current working directory
            return;
        end
        
        % Prompt the user for the CSV file name
        filename = input('Enter the CSV file name with extension: ', 's');

        try
            % Attempt to read the data from the provided filename
            readdata = csvread(filename);
    
            % Display the read data
            disp(readdata);
    
            % Plot the data
            plot(readdata);
    
            % Add labels and title
            xlabel('Time');
            ylabel('Microcontroller Readings');
            title('Real Time Microcontroller Readings');
    
        catch
            % Handle errors, e.g., if the file doesn't exist or contains non-numeric data
            disp('Error: Unable to read data from the specified file.');
        end

    case 2
        %% List all serial ports a board is connected to for the user to initialize connection
        serial_ports = serialportlist("available");
        fprintf('Available serial ports:\n');
        for i = 1:length(serial_ports)
            fprintf('%d: %s\n', i, serial_ports{i});
        end
        fprintf("\n");

        hold on;
        grid on;

        %% Make the plot a bit more clear
        set(groot, 'defaultlinelinewidth', 2);
        set(groot, 'defaultaxesxminortick', 'on');
        set(groot, 'defaultaxesyminortick', 'on');
        set(groot, 'defaulttextfontsize', 16); 
        set(groot, 'defaultaxesfontsize', 14);

        %% Connect to serial port and flush, initialize sample string
        port = input('Enter board port: ', 's');
        port = strtrim(port);
        baudrate = input("Enter baudrate: ");
        s1 = serial(port, baudrate);
        srl_flush(s1);
        sample = '';

        % Define the way Serial.print()'s are split depending on the code of the target board
        % It is recommended using "\t" in the microcontroller program
        % Using anything other than the escape character "\t" for delimiter produces unexpected results
        delimiter = input('Enter the signal delimiter: ', 's');

        %% Read one line here to figure out how many signals there are
        while true
            % Read one character at a time
            data = srl_read(s1,1);                           
            % If LF (end of Serial.println)
            if (data != 10)                                  
                sample = strcat(sample,char(data));
            else
                % Split sample based on the uploaded code to the target board, strsplit returns a cell array
                values = strsplit(sample, delimiter);            
                num_signals = size(values)(2);
                % Reset sample string
                sample = '';                                 
                break;
            end
        endwhile

        % Create the x-axis vector
        x = linspace(0, 1000, 1000);                       
        buffSize = 1000;
        % Array dimensions
        sampleBuff = zeros(num_signals, buffSize); 

        for i=1:num_signals
            % Initialize empty plots
            plot(nan);                                                  
        endfor

        % Get handle (vector of the line objects)
        p = findobj(gca, 'Type', 'line');                                 

        for i=1:num_signals
            % Set the x-axis to the sample index
            set(p(i), "xdata", x);                                     
        endfor

        %% Clear the I/O buffers of the serial port to clear any old data and start reading 
        unwind_protect
            fprintf("\n");
            % Implemented in the while loop, prints port values in the command line
            fprintf("Press space to toggle data display\n");
            % If an interrupt is initiated, it branches to srl_close(s1);
            fprintf("Interrupt process (Ctrl + C) to export data in CSV\n");
            % Variable to control whether to print values to the terminal
            % Pre-set to false to avoid unwanted output flooding
            printToTerminal = false;

            srl_flush(s1);
            while true        
                % Read one character at a time
                data = srl_read(s1, 1); 
                % If LF (end of Serial.println)        
                if (data != 10)                                          
                    sample = strcat(sample, char(data));
                else 
                    values = strsplit(sample, delimiter);
                    valvec = cellfun(@str2num, values, 'UniformOutput', false);
                    % Reset sample string
                    sample = '';                                         
                    sampleBuff = [cell2mat(valvec)' sampleBuff(:, 1:end-1)];

                    % Check if the user pressed space in the command prompt
                    if (kbhit(1) == ' ')
                        % Toggle the variable 
                        printToTerminal = ~printToTerminal;
                    end
                    % Display received data in the terminal if true
                    if printToTerminal
                        fprintf('Received data: %s\n', strjoin(values, '\t'));
                    end

                    % For debugging
                    % fprintf('Sample Buffer Size: %dx%d\n', size(sampleBuff));
                    for i=1:num_signals
                        set(p(i), "ydata", sampleBuff(i, :));
                        drawnow
                    endfor
                endif
            endwhile
        unwind_protect_cleanup
            srl_close(s1);
            fprintf ('Caught interrupt. Save data?\n');
            choice = input('Enter "y" to export, or any other key to skip: ', 's');
            if strcmpi(choice, 'y')
                fprintf('Exporting data to CSV...\n');

                % Prompt the user to enter a custom filename
                customFilename = input('Enter a custom filename (without extension): ', 's');

                % Generate the full filename with the provided custom filename and timestamp
                filename = strcat(customFilename, '_', datestr(now(), 'yyyymmddHHMMSS'), '.csv');

                % Save your data
                csvwrite(filename, sampleBuff');

                fprintf('Data exported to: %s\n', filename);
            else
                fprintf('Data export skipped.\n');
            end
        end
end
