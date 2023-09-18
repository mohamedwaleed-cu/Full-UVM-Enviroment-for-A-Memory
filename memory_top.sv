`include "uvm_macros.svh"

interface intf1;
logic clk;
logic [3:0] address;
logic rst;
logic en;
logic we;
logic [7:0] data_in;
logic [7:0] data_out;

endinterface


module memory(intf1 dintf );

import uvm_pkg::*;

reg [31:0] mem [15:0];
reg [31:0] temp;


always @ (posedge dintf.clk  )
begin
	if(!dintf.rst)
	begin
	mem[0] <= 0;
	mem[1] <= 0;
	mem[2] <= 0;
	mem[3] <= 0;
	mem[4] <= 0;
	mem[5] <= 0;
	mem[6] <= 0;
	mem[7] <= 0;
	mem[8] <= 0;
	mem[9] <= 0;
	mem[10] <= 0;
	mem[11] <= 0;
	mem[12] <= 0;
	mem[13] <= 0;
	mem[14] <= 0;
	mem[15] <= 0;
	end
	else
	begin
		if(dintf.en & dintf.we)
		mem[dintf.address] <= dintf.data_in;
		else if(dintf.en & !dintf.we)
		dintf.data_out <= mem[dintf.address];
		else
		mem[dintf.address] <= mem[dintf.address];

	end


end

  always @(posedge dintf.clk)
  begin
    `uvm_info("", $sformatf("DUT received en=%b, we=%d, addr=%d, data=%d  output=%d",
                            dintf.en, dintf.we, dintf.address, dintf.data_in ,dintf.data_out), UVM_LOW)
  end

//assign dintf.data_out = (dintf.en & !dintf.we) ? temp : 0; 
endmodule