# Serial-Plotter
An octave utility tool to read inputs from the serial port and plot them into a real time graph.
This project was made to allow microcontroller readings to be turned into real time graphs as well as saving the readings into CSV files.
It can handle more than one graph.
PlatformIO lacks this tool and I found no reason to install additional software for graphs.
To use simply input the port(the script scans for used ports), baudrate and signal delimiter and a plot will automatically be generated.
Interrupting the process will prompt the user whether they want the data exported into a CSV file.
It's only compatible with Octave, not MATLAB.
