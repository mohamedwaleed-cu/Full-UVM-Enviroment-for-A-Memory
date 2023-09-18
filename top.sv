module top;
import uvm_pkg::*;
import pack1::*;

intf1 in1();

memory dut(.dintf(in1));


  // Clock generator
  initial
  begin
    in1.clk = 0;
    forever #5 in1.clk = ~in1.clk;
  end

initial 
begin

uvm_config_db #(virtual intf1)::set(null,"uvm_test_top","my_vif",in1);

run_test("my_test");
end


endmodule
