# What?
This repo contains files to run a stream in demo where data are transmitted by an FPGA board to the PC host through the FX3 USB 3.0 dev kit.

# Requirements?

This project requires some hardware components which are listed below:

- [EZ-USB FX3](https://www.cypress.com/products/ez-usb-fx3-superspeed-usb-30-peripheral-controller) is a development board with a USB 3.0 interface. It embeds a USB 3.0 FIFO chip from Cypress that enables easy integration of the USB 3.0 protocol in custom system.
In our case, this dev kit will be attached to an FPGA board.

- To connect the FX3 dev kit and our FPGA board, you need the [CYUSB3ACC-005 FMC Interconnect Board](https://www.cypress.com/documentation/development-kitsboards/cyusb3acc-005-fmc-interconnect-board-ez-usb-fx3-superspeed).

- **ZedBoard Zynq-7000** is a low-cost development board embeds a Xilinx Zynq 7000 SoC. 
Such SoC combines an FPGA fabric and a dual-core ARM processor. Detailed information [here](https://store.digilentinc.com/zedboard-zynq-7000-arm-fpga-soc-development-board/).
This board 

Regarding software requirements, this project has been tested using Vivado v2019.1 (64-bit).
FX3 firmware has been compiled with gcc (Ubuntu 9.3.0-17ubuntu1~20.04) 9.3.0.
Operating system: Ubuntu 20.04.1 LTS.

# How to install?

Installation should be pretty easy using the different scripts.
You need to flash the FPGA board and the FX3 dev kit.
For the sake of simplicity, we only describe how to install from source.

## FPGA installation
First, change the boot mode on the Zedboard. 
Required jumper configuration:
```
JMP11 OFF
JMP10 OFF
JMP9  OFF
JMP8  OFF
```

Then, run the ```install.sh``` script. This latter runs Vivado to generate the FPGA bitfile and call the ```flash.sh``` script to flash the Xilinx SoC.
```
./install.sh
```

When the flash process finishes, power-off the FPGA and restore boot configuration as follow.
```
JMP11 OFF
JMP10 ON
JMP9  OFF
JMP8  OFF
```

## FX3 installation

Please, close all jumpers on the FX3 board before running the ```make load``` command (i.e., flash the FX3 board).
The ```make install_sdk``` command requires ```root``` priviledge to install the required files on your system. 
If you do not want to install the sdk globally, feel free to modify the ```install_sdk.sh``` script.


> **SDK download:** The CMake script tried to download the fx3 sdk from the official Cypress website. If you encounter any issue, [just download it manually](https://www.cypress.com/file/424271/download).

```
cd fx3
mkdir build && cd build
cmake .. && make 
make install_sdk
make load
```

# Evaluating Performance

Using Cypress SDK, we measured a throughput of 380MB/s.
> This measure may vary with the Operating System, the USB3.0 chip controler on your PC, and the driver you are using.
```
./09_cyusb_performance -e 129 -s 32 -q 8 -d 10
```

![Performance](./doc/perf.svg)


| FPGA Clock Frequency | 60MHz    | 95MHz    | 100MHz   |
|----------------------|----------|----------|----------|
| USB 3.0 Throughput   | 280MB/s  | 350MB/s  | 390MB/s  |

> Note: At 100MHz, I observed inconsistency on received data. This is because our set-up cannot ensure such timing. It could be fixed by designing a custom PCB with shorter path between the Cypress FIFO chip and the FPGA. 

# Debugging the FX3 firmware

Debugging the fx3 firmware program works well with Open On-Chip Debugger 0.10.0+dev-01404-g393448342-dirty (2020-11-08-11:56).
> I could not compile OpenOCD from source using GCC 10 and release 0.10, but it works with well with commit: ```3934483429b77525f25922787933fb7ee3e73a0f```.

```
cd fx3

openocd -f interface/openjtag.cfg -c "openjtag_variant CY7C65215" -f ./arm926ejs_fx3.cfg
```

I provide a gdb script to load the firmware program, put breakpoint at main and run code.

```
cd fx3

gdb-multiarch -x ./load.gdb
```

The FX3 firmware program sends feedback through the micro-USB interface.
```
picocom -b115200 -fn -d8 -r -l /dev/ttyACM0
```

# LICENSE

All files copied from Cypress examples are under the CYPRESS SOFTWARE LICENSE AGREEMENT.
The Synthesis script is under the CeCILL license
All other files are under the GNU GPL3 license.

# Credits

This project is based on the following projects:
- The FX3 firmware and the GPIF configuration is a fork of [DomesdayDuplicator](https://github.com/simoninns/DomesdayDuplicator).
- We refer to the [official examples](https://www.cypress.com/documentation/code-examples/usb-superspeed-code-examples) provided by Cypress.
- The synthesis script are forked from [SAB4Z](https://gitlab.telecom-paris.fr/renaud.pacalet/sab4z)


