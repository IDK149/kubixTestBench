YOSYS_COLORLIGHT_OPT = -DCOLORLIGHT -q -p "synth_ecp5 -top $(PROJECTNAME) -json $(PROJECTNAME).json"
NEXTPNR_COLORLIGHT_OPT = --force --json $(PROJECTNAME).json --lpf BOARDS/colorlight.lpf \
												 --textcfg $(PROJECTNAME)_out.config --25k --package CABGA256

#######################################################################################################################

COLORLIGHT: COLORLIGHT.firmware_config COLORLIGHT.synth COLORLIGHT.prog

COLORLIGHT.synth: FIRMWARE/firmware.hex 
	TOOLS/make_config.sh -DCOLORLIGHT
	yosys $(YOSYS_COLORLIGHT_OPT) $(VERILOGS)
	nextpnr-ecp5 $(NEXTPNR_COLORLIGHT_OPT)
	ecppack --compress --svf-rowsize 100000 --svf $(PROJECTNAME).svf $(PROJECTNAME)_out.config $(PROJECTNAME).bit

COLORLIGHT.prog:
	openFPGALoader --cable ft232RL --pins=0:3:4:1 --freq 3000000 -b colorlight $<

COLORLIGHT.prog_flash: $(PROJECTNAME).bit
	openFPGALoader --cable ft232RL --pins=0:3:4:1 --freq 3000000 -b colorlight -f $<

COLORLIGHT.firmware_config:
	BOARD=colorlight TOOLS/make_config.sh -DCOLORLIGHT
	(cd FIRMWARE; make libs)
