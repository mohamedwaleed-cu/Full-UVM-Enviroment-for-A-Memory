typedef class Env;
`include "memory_top.sv"
class transaction ;
logic [31:0] data_in;
logic [3:0]  Adress;
logic En;
logic WE;
logic Clk;
logic rst;
logic [31:0] data_out;
endclass

class Sequencer ;

transaction t1;
	function void s_assign;
	t1=new();
	t1.data_in=32'b0000000000001111;
	t1.Adress=4'b0010;
	t1.En=1;
	t1.WE=1;
	t1.Clk=1;
	t1.rst=0;
	endfunction
	
	function transaction d_assign;
	return t1;
	endfunction


endclass
class driver ;
transaction t2;

function new;
t2=new();

endfunction

endclass

class monitor ;
transaction t3;
	function new;
	t3=new();
	endfunction
	function void display;
	$display(t3.data_out);
	endfunction
endclass



class Env;

Sequencer s1;
driver d1;
monitor m1;

function new();
s1=new();
d1=new;
m1=new;
s1.s_assign();
d1.t2=s1.d_assign;


endfunction 



endclass

interface intf;
logic [31:0] data_in;
logic [3:0]  Adress;
logic En;
logic WE;
logic Clk;
logic rst;
logic [31:0] data_out;
endinterface

module tb;
Env e1;
intf intf1();
virtual intf vif;
memory mem1(.indata(intf1.data_in),.CLK(intf1.Clk),.RST(intf1.rst),
.EN(intf1.En),.WE(intf1.WE),.address(intf1.Adress),.outdata(intf1.data_out));

always #2 vif.Clk=~vif.Clk;

initial
begin
e1=new();
vif=intf1;
vif.data_in=e1.d1.t2.data_in;
vif.Adress=e1.d1.t2.Adress;
vif.En=e1.d1.t2.En;
vif.WE=e1.d1.t2.WE;
vif.Clk=e1.d1.t2.Clk;
vif.rst=e1.d1.t2.rst;
e1.m1.t3.data_out=vif.data_out;



#10 e1.m1.display();
end


endmodule