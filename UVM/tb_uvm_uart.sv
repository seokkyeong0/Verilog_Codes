`include "uvm_macros.svh"
import uvm_pkg::*;

// UART Baud Rate Setup
`define BAUD 115200
`define BIT_TIME 1_000_000_000 / `BAUD
`define BIT_CYCLE `BIT_TIME / 10

// UART Interface
interface uart_intf (
    input logic clk,
    input logic reset
);
    logic rx_in;
    logic tx_out;
    logic error_flag;

    // Systemverilog Assertion (SVA)
    // Stop Bit Check
    property stop_bit_check;
        @(posedge clk) disable iff (reset)
        // Start Bit Detect
        ($fell(
            tx_out
        )) |=> ##(`BIT_CYCLE*9+`BIT_CYCLE/2) (tx_out == 1);
    endproperty

    a_stop_bit_check :
    assert property (stop_bit_check)
    else begin
        error_flag <= 1;
        `uvm_error("SVA", "Stop Bit Error Occurred")
    end
endinterface

// FIFO Monitor
module fifo_rx_monitor #(parameter WIDTH = 8)(
    input logic clk,
    input logic rst,
    input logic push,
    input logic pop,
    input logic [WIDTH-1:0] wdata,
    input logic [WIDTH-1:0] rdata,
    input logic full,
    input logic empty
);
    always @(posedge clk) begin
        if(push) $display("[%0t][FIFO_RX_MON] PUSH : %0h", $time, wdata);
        if(pop) $display("[%0t][FIFO_RX_MON] POP : %0h", $time, rdata);
    end
endmodule

module fifo_tx_monitor #(parameter WIDTH = 8)(
    input logic clk,
    input logic rst,
    input logic push,
    input logic pop,
    input logic [WIDTH-1:0] wdata,
    input logic [WIDTH-1:0] rdata,
    input logic full,
    input logic empty
);
    always @(posedge clk) begin
        if(push) $display("[%0t][FIFO_TX_MON] PUSH : %0h", $time, wdata);
        if(pop) $display("[%0t][FIFO_TX_MON] POP : %0h", $time, rdata);
    end
endmodule

bind uart fifo_rx_monitor fifo_rx_mon (
    .clk(clk),
    .rst(reset),
    .push(U_FIFO_RX.push),
    .pop(U_FIFO_RX.pop),
    .wdata(U_FIFO_RX.wdata),
    .rdata(U_FIFO_RX.rdata),
    .full(U_FIFO_RX.full),
    .empty(U_FIFO_RX.empty)
);

bind uart fifo_tx_monitor fifo_tx_mon (
    .clk(clk),
    .rst(reset),
    .push(U_FIFO_TX.push),
    .pop(U_FIFO_TX.pop),
    .wdata(U_FIFO_TX.wdata),
    .rdata(U_FIFO_TX.rdata),
    .full(U_FIFO_TX.full),
    .empty(U_FIFO_TX.empty)
);

// Functional Coverage Class
// Functional coverage deals with covering design functionality or feature metrics. It is a user-defined metric that tells about how much design specification or functionality has been exercise.
class uart_coverage extends uvm_object;
    `uvm_object_utils(uart_coverage)

    rand bit [7:0] data;
    rand bit       stop_error;

    covergroup u_cg;
        option.per_instance = 1;

        // Add Weight Option for coverage caculation
        coverpoint data {
            bins all_data[] = {[0 : 255]}; option.weight = 256;
        }

        coverpoint stop_error {
            bins no_error = {0}; ignore_bins error = {1}; option.weight = 2;
        }
    endgroup

    function new(string name = "COV");
        super.new(name);
        u_cg = new();
    endfunction

    function void sample ();
        u_cg.sample();
    endfunction
endclass

// Sequence Item Class (Transaction)
// The sequence item class contains necessary stimulus generation data members.
class uart_seq_item extends uvm_sequence_item;

    // UART items
    rand bit [7:0] send_data;
    bit [7:0] recv_data;
    bit rx_in;
    bit tx_out;
    bit is_exp;
    bit stop_error;

    function new(string name = "ITEM");
        super.new(name);
    endfunction

    `uvm_object_utils_begin(uart_seq_item)
        `uvm_field_int(send_data, UVM_DEFAULT)
        `uvm_field_int(recv_data, UVM_DEFAULT)
        `uvm_field_int(rx_in, UVM_DEFAULT)
        `uvm_field_int(tx_out, UVM_DEFAULT)
        `uvm_field_int(is_exp, UVM_DEFAULT)
        `uvm_field_int(stop_error, UVM_DEFAULT)
    `uvm_object_utils_end
endclass

// Sequence Class
// The sequence creates the stimulus and drives them to the driver via sequencer.
class uart_sequence extends uvm_sequence #(uart_seq_item);

    // Add to factory
    `uvm_object_utils(uart_sequence)

    uart_seq_item u_item;

    function new(string name = "SEQ");
        super.new(name);
    endfunction

    task body();
        u_item = uart_seq_item::type_id::create("ITEM");
        for (int i = 0; i < 2000; i++) begin
            start_item(u_item);
            assert (u_item.randomize())
            else `uvm_error("SEQ", "Randomize Failed")
            `uvm_info("SEQ", $sformatf(
                      "[%0d][SEQ -> DRV] send_data = %0h", i, u_item.send_data),
                      UVM_NONE)
            finish_item(u_item);
        end
        // Wait last tx_done
        #(`BAUD);
    endtask

endclass

// Sequencer Class
// The sequencer is a mediator who establishes a connection between sequence and driver.
// uvm_sequencer #(uart_seq_item) u_sqr;

// Driver Class
// The driver drives randomized transactions or sequence items to DUT as a pin-level activity using an interface.
class uart_driver extends uvm_driver #(uart_seq_item);

    // Add to factory
    `uvm_component_utils(uart_driver)
    uvm_analysis_port #(uart_seq_item) expt;

    virtual uart_intf u_if;
    uart_seq_item u_item;

    function new(string name = "DRV", uvm_component parent);
        super.new(name, parent);
        expt = new("expt", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        u_item = uart_seq_item::type_id::create("ITEM", this);
        if (!uvm_config_db#(virtual uart_intf)::get(this, "", "u_if", u_if))
            `uvm_fatal("DRV", "Unable to get interface")
    endfunction

    // Bit production helper
    task send_bit(bit b, int bit_time);
        u_if.rx_in = b;
        #(bit_time);
    endtask

    // Driver to the DUT
    int i = 0;
    task run_phase(uvm_phase phase);
        #50;  // After reset
        forever begin

            seq_item_port.get_next_item(u_item);

            u_item.is_exp = 1;
            expt.write(u_item);
            u_item.is_exp = 0;
            `uvm_info("DRV", $sformatf(
                      "[%0d][DRV -> DUT] send_data = %0h", i++, u_item.send_data
                      ), UVM_NONE)

            // Start Bit
            send_bit(0, `BIT_TIME);

            // Data Bit
            for (int b = 0; b < 8; b++) begin
                send_bit(u_item.send_data[b], `BIT_TIME);
            end

            // Stop Bit
            send_bit(1, `BIT_TIME);

            // Wait TX_done (optional)
            #(`BIT_TIME * 10);

            seq_item_port.item_done();
        end
    endtask
endclass

// Monitor Class
// A UVM Monitor is a passive component used to capture DUT signals using a virtual interface and translate them into a sequence item format.
class uart_monitor extends uvm_monitor;

    `uvm_component_utils(uart_monitor)

    uvm_analysis_port #(uart_seq_item) send;
    virtual uart_intf u_if;
    uart_seq_item u_item;
    uart_coverage u_cov;

    function new(string name = "MON", uvm_component parent);
        super.new(name, parent);
        send  = new("send", this);
        u_cov = uart_coverage::type_id::create("u_cov", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        u_item = uart_seq_item::type_id::create("ITEM", this);
        if (!uvm_config_db#(virtual uart_intf)::get(
                this, "", "u_if", u_if
            )) begin
            `uvm_fatal("MON", "Unable to get interface")
        end
    endfunction

    // Bit production helper
    task recv_bit(int i, bit b, int bit_time);
        u_item.recv_data[i] = b;
        #(bit_time);
    endtask

    int i = 0;
    task run_phase(uvm_phase phase);
        #50;  // After reset
        forever begin
            // Wait for start bit & Sampling Timing
            @(negedge u_if.tx_out);
            #(`BIT_TIME / 2);
            #(`BIT_TIME);

            // Data bits
            for (int i = 0; i < 8; i++) begin
                recv_bit(i, u_if.tx_out, `BIT_TIME);
            end

            // Stop Bit Check
            u_item.stop_error = u_if.error_flag;
            u_if.error_flag = 0;  // Clear for next transaction

            // Coverage Sampling
            u_cov.data = u_item.recv_data;
            u_cov.stop_error = u_item.stop_error;
            u_cov.sample();

            `uvm_info("MON", $sformatf(
                      "[%0d][MON -> SCB] recv_data = %0h", i++, u_item.recv_data
                      ), UVM_NONE)
            send.write(u_item);
        end
    endtask
endclass

// Agent Class
// An agent is a container that holds and connects the driver, monitor, and sequencer instances.
class uart_agent extends uvm_agent;

    `uvm_component_utils(uart_agent)

    uart_driver u_drv;
    uart_monitor u_mon;
    uvm_sequencer #(uart_seq_item) u_sqr;

    function new(string name = "AGT", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        u_drv = uart_driver::type_id::create("DRV", this);
        u_mon = uart_monitor::type_id::create("MON", this);
        u_sqr = uvm_sequencer#(uart_seq_item)::type_id::create("SQR", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        u_drv.seq_item_port.connect(u_sqr.seq_item_export);
    endfunction
endclass

// Scoreboard Class
// The UVM scoreboard is a component that checks the functionality of the DUT. It receives transactions from the monitor using the analysis export for checking purposes.
class uart_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(uart_scoreboard)

    // Separated Analysis Ports
    uvm_analysis_imp #(uart_seq_item, uart_scoreboard) expt;
    uvm_analysis_imp #(uart_seq_item, uart_scoreboard) recv;

    uart_seq_item u_item;
    logic [7:0] exp_item[$];

    function new(string name = "SCB", uvm_component parent);
        super.new(name, parent);
        expt = new("expt", this);
        recv = new("recv", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        u_item = uart_seq_item::type_id::create("ITEM", this);
    endfunction

    int i = 0;
    function void write(input uart_seq_item item);
        if (item.is_exp) begin
            exp_item.push_front(item.send_data);
        end else begin
            u_item.send_data = exp_item.pop_back();
            `uvm_info("SCB", $sformatf(
                      "[%0d][SCB] recv_data = %0h", i, item.recv_data),
                      UVM_NONE)
            if (u_item.send_data == item.recv_data) begin
                `uvm_info("SCB",
                          $sformatf(
                              "[%0d]Passed: send_data = %0h, recv_data = %0h",
                              i++, u_item.send_data, item.recv_data), UVM_NONE)
            end else begin
                `uvm_error("SCB", $sformatf(
                           "[%0d]Failed: send_data = %0h, recv_data = %0h",
                           i++,
                           u_item.send_data,
                           item.recv_data
                           ))
            end
        end
    endfunction
endclass

// Environment Class
// An environment provides a container for agents, scoreboards, and other verification components.
class uart_environment extends uvm_env;

    `uvm_component_utils(uart_environment)

    uart_agent u_agt;
    uart_scoreboard u_scb;

    function new(string name = "ENV", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        u_agt = uart_agent::type_id::create("AGT", this);
        u_scb = uart_scoreboard::type_id::create("SCB", this);
    endfunction

    // Monitor to Scoreboard
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        u_agt.u_drv.expt.connect(u_scb.expt);  // TLM communication(UVM)
        u_agt.u_mon.send.connect(u_scb.recv);  // TLM communication(UVM)
    endfunction
endclass

// Test Class
// The test is at the top of the hierarchical component that initiates the environment component construction.
class uart_test extends uvm_test;

    `uvm_component_utils(uart_test)

    uart_sequence u_seq;
    uart_environment u_env;

    function new(string name = "TEST", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        u_env = uart_environment::type_id::create("ENV", this);
        u_seq = uart_sequence::type_id::create("SEQ", this);
    endfunction

    // Factory Structure
    function void start_of_simulation_phase(uvm_phase phase);
        super.start_of_simulation_phase(phase);
        uvm_root::get().print_topology();
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        u_seq.start(u_env.u_agt.u_sqr);
        phase.drop_objection(this);
    endtask
endclass

// Testbench Top Module
// The testbench top is a static container that has an instantiation of DUT and interfaces.
module tb_uvm_uart ();

    logic clk, reset;

    uart_intf u_if (
        clk,
        reset
    );

    uart #(
        .BAUD(`BAUD)
    ) dut (
        .clk(u_if.clk),
        .reset(u_if.reset),
        .rx_in(u_if.rx_in),
        .tx_out(u_if.tx_out)
    );

    always #5 clk = ~clk;

    initial begin
        #00 clk = 0;
        reset = 1;
        u_if.rx_in = 1;
        #10 reset = 0;
    end

    initial begin
        $fsdbDumpvars(0);
        $fsdbDumpfile("wave.fsdb");

        uvm_config_db#(virtual uart_intf)::set(null, "*", "u_if", u_if);
        run_test("uart_test");
        #100;
        $finish;
    end
endmodule
