package pack1;

import uvm_pkg::*;
`include "uvm_macros.svh"


class my_sequence_item extends uvm_sequence_item;
	`uvm_object_utils(my_sequence_item)

function new (string name="my_sequence_item");
	super.new(name);
endfunction

//simple function in the sequence item//

function void print (string s);
	$display("%s",s);
endfunction

//Defining Signal and putting constraints on it //

rand bit [7:0] data_in;
rand bit [3:0] address;
rand bit rst;
rand bit en;
rand bit we;
logic [7:0] data_out;

constraint const1 {rst dist {0:=1,1:=9};} //rst is constrained with probabilty 10% for 0 and 90% for 1
constraint const2 {en dist {0:=1,1:=9};}  //en is constrained with probabilty 10% for 0 and 90% for 1
constraint const3 {we dist {0:=7,1:=3};}  //we is constrained with probabilty 70% for 0 and 30% for 1


endclass


class my_sequence extends uvm_sequence;
	`uvm_object_utils(my_sequence)	

my_sequence_item sequence1;
my_sequence_item sequence2;

task pre_body;
	sequence1=my_sequence_item::type_id::create("sequence1");
	sequence2=my_sequence_item::type_id::create("sequence2");
endtask

task body;
	repeat(4)
	begin
	start_item(sequence1);
	void'(sequence1.randomize());
	sequence1.data_in=$urandom_range(0,199);
	finish_item(sequence1);

	start_item(sequence2);
	void'(sequence2.randomize());
	sequence2.data_in=$urandom_range(200,399);
	finish_item(sequence2);
	end
endtask




endclass


class my_driver  extends uvm_driver #(my_sequence_item);

`uvm_component_utils(my_driver)



my_sequence_item sequence1;
my_sequence_item sequence2;






function new (string name="my_driver",uvm_component parent = null);
	super.new(name,parent);
endfunction


virtual interface intf1 config_virtual;


function void build_phase (uvm_phase phase);
	if(!uvm_config_db#(virtual intf1)::get(this,"","my_vif",config_virtual))
	`uvm_fatal(get_full_name(),"EEROR!")
	$display(config_virtual);

	super.build_phase(phase);
	$display("driver is built");
	sequence1=my_sequence_item::type_id::create("sequence1");
	sequence2=my_sequence_item::type_id::create("sequence2");
endfunction

function void connect_phase (uvm_phase phase);
	super.connect_phase(phase);
	$display("driver is connected");
endfunction

//run phase methods
task run_phase(uvm_phase phase);
	super.run_phase(phase);
	
	forever begin
	seq_item_port.get_next_item(sequence1);
	//sending data to the DUT
	@(posedge config_virtual.clk)
	begin
	config_virtual.data_in <= sequence1.data_in;
	config_virtual.address <= sequence1.address;
	config_virtual.rst <= sequence1.rst;
	config_virtual.en <= sequence1.en;
	config_virtual.we <= sequence1.we;
	end
	#1 seq_item_port.item_done(sequence1);
	end

	forever begin
	seq_item_port.get_next_item(sequence2);
	//sending data to the DUT
	@(posedge config_virtual.clk)
	begin
	config_virtual.data_in <= sequence2.data_in;
	config_virtual.address <= sequence2.address;
	config_virtual.rst <= sequence2.rst;
	config_virtual.en <= sequence2.en;
	config_virtual.we <= sequence2.we;
	end
	#1 seq_item_port.item_done(sequence2);
	end

	
endtask

endclass

class my_sequencer extends uvm_sequencer #(my_sequence_item);
`uvm_component_utils(my_sequencer)


function new (string name="my_sequencer",uvm_component parent = null);
	super.new(name,parent);
endfunction

function void build_phase (uvm_phase phase);
	super.build_phase(phase);
	$display("sequencer is built");
	
endfunction

function void connect_phase (uvm_phase phase);
	super.connect_phase(phase);
	$display("sequencer is connected");
endfunction

//run phase methods
task run_phase(uvm_phase phase);
	super.run_phase(phase);
endtask

endclass

class my_monitor extends uvm_monitor;
`uvm_component_utils(my_monitor)
uvm_analysis_port #(my_sequence_item) my_analysis_port;

my_sequence_item sequence1;
my_sequence_item sequence2;


function new (string name="my_monitor",uvm_component parent = null);
	super.new(name,parent);
endfunction


virtual interface intf1 config_virtual;


function void build_phase (uvm_phase phase);
	if(!uvm_config_db#(virtual intf1)::get(this,"","my_vif",config_virtual))
	`uvm_fatal(get_full_name(),"EEROR!")
	$display(config_virtual);

	super.build_phase(phase);
	$display("monitor is built");
	my_analysis_port=new("my_analysis_port",this);
	sequence1=my_sequence_item::type_id::create("sequence1");
	sequence2=my_sequence_item::type_id::create("sequence2");	
endfunction

function void connect_phase (uvm_phase phase);
	super.connect_phase(phase);
	$display("monitor is connected");
endfunction

//run phase methods
task run_phase(uvm_phase phase);
	
	forever begin
		@(posedge config_virtual.clk)
		sequence1.data_out <= config_virtual.data_out ;
		$display("From monitor %d",config_virtual.data_out);
	
		my_analysis_port.write(sequence1);
	
		end
endtask

endclass

class my_scoreboard extends uvm_scoreboard;
`uvm_component_utils(my_scoreboard)

uvm_analysis_export #(my_sequence_item) my_analysis_export;
uvm_tlm_analysis_fifo #(my_sequence_item) my_analysis_fifo;

my_sequence_item sequence1;

function new (string name="my_scoreboard",uvm_component parent = null);
	super.new(name,parent);
endfunction

function void build_phase (uvm_phase phase);
	super.build_phase(phase);
	$display("scoreboard is built");
	my_analysis_export=new("my_analysis_export",this);
	my_analysis_fifo=new("my_analysis_fifo",this);
endfunction

function void connect_phase (uvm_phase phase);
	super.connect_phase(phase);
	$display("scoreboard is connected");
	my_analysis_export.connect(my_analysis_fifo.analysis_export);

endfunction

//run phase methods
task run_phase(uvm_phase phase);
	forever begin
	my_analysis_fifo.get_peek_export.get(sequence1);
	$display("from scoreboard %d",sequence1.data_out);
	// HERE we could add compare function if we had an expected value file//
	end
endtask


function void write (my_sequence_item t);
	t.print("HELLO from scoreboard");
endfunction


endclass

class my_subscriber extends uvm_subscriber #(my_sequence_item);
`uvm_component_utils(my_subscriber)

uvm_analysis_imp #(my_sequence_item,my_subscriber) my_analysis_imp;

my_sequence_item sequence1;

//making a covergroup for all ranges

covergroup group1;
	coverpoint sequence1.data_in {bins bin_1[]={[0:400]};}
	coverpoint sequence1.address {bins bin_1[]={[0:15]};}
	coverpoint sequence1.we {bins bin_1={[0:1]};}
	coverpoint sequence1.en {bins bin_1={[0:1]};}
	coverpoint sequence1.rst {bins bin_1={[0:1]};}
	cross_1:cross sequence1.data_in,sequence1.address,sequence1.we,sequence1.en,sequence1.rst;
endgroup


function new (string name="my_subscriber",uvm_component parent = null);
	super.new(name,parent);
	group1=new();
endfunction



function void write (my_sequence_item t);
	t.print("HI from subscriber");
	sequence1=t;
	group1.sample();
endfunction

function void build_phase (uvm_phase phase);
	super.build_phase(phase);
	$display("subscriber is built");
	
	my_analysis_imp=new("my_analysis_imp",this);
endfunction

function void connect_phase (uvm_phase phase);
	super.connect_phase(phase);
	$display("subscriber is connected");
endfunction

//run phase methods
task run_phase(uvm_phase phase);
	super.run_phase(phase);
endtask


endclass

class my_agent extends uvm_agent;
`uvm_component_utils(my_agent)
uvm_analysis_port #(my_sequence_item) my_analysis_port;

function new (string name="my_agent",uvm_component parent = null);
	super.new(name,parent);
endfunction

my_driver d1;
my_sequencer s1;
my_monitor m1;


virtual interface intf1 config_virtual;
virtual interface intf1 local_virtual;

function void build_phase (uvm_phase phase);
	if(!uvm_config_db#(virtual intf1)::get(this,"","my_vif",config_virtual))
	`uvm_fatal(get_full_name(),"EEROR!")

	local_virtual=config_virtual;

	uvm_config_db#(virtual intf1)::set(this,"d1","my_vif",local_virtual);
	uvm_config_db#(virtual intf1)::set(this,"m1","my_vif",local_virtual);

	my_analysis_port=new("my_analysis_port",this);

	super.build_phase(phase);
	$display("agent is built");
	d1=my_driver::type_id::create("d1",this);
	s1=my_sequencer::type_id::create("s1",this);
	m1=my_monitor::type_id::create("m1",this);
endfunction

function void connect_phase (uvm_phase phase);
	super.connect_phase(phase);
	$display("agent is connected");
	m1.my_analysis_port.connect(this.my_analysis_port);

	d1.seq_item_port.connect(s1.seq_item_export);	

endfunction

//run phase methods
task run_phase(uvm_phase phase);
	super.run_phase(phase);
endtask

endclass

class my_env extends uvm_env;
`uvm_component_utils(my_env)

function new (string name="my_env",uvm_component parent = null);
	super.new(name,parent);
endfunction

my_agent a1;
my_subscriber su1;
my_scoreboard sb1;


virtual interface intf1 config_virtual;
virtual interface intf1 local_virtual;

function void build_phase (uvm_phase phase);
	if(!uvm_config_db#(virtual intf1)::get(this,"","my_vif",config_virtual))
	`uvm_fatal(get_full_name(),"EEROR!")

	local_virtual=config_virtual;

	su1=my_subscriber::type_id::create("su1",this);
	sb1=my_scoreboard::type_id::create("sb1",this);
	a1=my_agent::type_id::create("a1",this);

	uvm_config_db#(virtual intf1)::set(this,"a1","my_vif",local_virtual);


	super.build_phase(phase);
	$display("Env is built");

endfunction

function void connect_phase (uvm_phase phase);
	super.connect_phase(phase);
	$display("Env is connected");
	a1.my_analysis_port.connect(sb1.my_analysis_export);
	a1.my_analysis_port.connect(su1.my_analysis_imp);
endfunction

//run phase methods
task run_phase(uvm_phase phase);
	super.run_phase(phase);
endtask


endclass

class my_test extends uvm_test;
`uvm_component_utils(my_test)

function new (string name="my_test",uvm_component parent = null);
	super.new(name,parent);
endfunction

my_env e1;
my_sequence seq1;

virtual interface intf1 config_virtual;
virtual interface intf1 local_virtual;

function void build_phase (uvm_phase phase);
	if(!uvm_config_db#(virtual intf1)::get(this,"","my_vif",config_virtual))
	`uvm_fatal(get_full_name(),"EEROR!")

	seq1=my_sequence::type_id::create("seq1");
	e1=my_env::type_id::create("e1",this);

	local_virtual=config_virtual;

	uvm_config_db#(virtual intf1)::set(this,"e1","my_vif",local_virtual);

	super.build_phase(phase);
	$display("test is built");

endfunction

function void connect_phase (uvm_phase phase);
	super.connect_phase(phase);
	$display("test is connected");
endfunction

//run phase methods
task run_phase(uvm_phase phase);
	super.run_phase(phase);

	phase.raise_objection(this);
	seq1.start(e1.a1.s1);
	phase.drop_objection(this);
	
	phase.raise_objection(this);
	seq1.start(e1.a1.s1);
	phase.drop_objection(this);

endtask

endclass

endpackage
