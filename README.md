# Serial-Plotter
An octave utility tool to read inputs from the serial port and plot them into a real time graph.\
This project was made to allow microcontroller readings to be turned into real time graphs as well as saving the readings into CSV files.\
It has two modes, reader and scanner.\
Reader mode scans current working directory for .csv files, waits for user input then prints the file's values and plots a graph.\
Scanner mode establishes a serial connection with a microcontroller to plot in real time incoming sensor data.\
It can handle more than one graph.\
Serial data can be printed in the console by toggling modes from the command line.\
PlatformIO lacks this tool and I found no reason to install additional software for graphs.\
To use simply input the port(the script scans for used ports), baudrate and signal delimiter and a plot will automatically be generated.\
Interrupting the process will prompt the user whether they want the data exported into a CSV file.\
It's only compatible with Octave, not MATLAB.
