`timescale 1ns/100ps
`define CYCLE       10.0
`define HCYCLE      (`CYCLE/2)
`define MAX_CYCLE   120000

`ifdef p0
    `define Inst "../00_TB/PATTERN/p0/inst.dat"
    `define Data "../00_TB/PATTERN/p0/data.dat"
    `define Status "../00_TB/PATTERN/p0/status.dat"
`elsif p1
    `define Inst "../00_TB/PATTERN/p1/inst.dat"
    `define Data "../00_TB/PATTERN/p1/data.dat"
    `define Status "../00_TB/PATTERN/p1/status.dat"
`elsif p2
	`define Inst "../00_TB/PATTERN/p2/inst.dat"
	`define Data "../00_TB/PATTERN/p2/data.dat"
	`define Status "../00_TB/PATTERN/p2/status.dat"
`elsif p3
	`define Inst "../00_TB/PATTERN/p3/inst.dat"
	`define Data "../00_TB/PATTERN/p3/data.dat"
	`define Status "../00_TB/PATTERN/p3/status.dat"
`else
	`define Inst "../00_TB/PATTERN/p0/inst.dat"
	`define Data "../00_TB/PATTERN/p0/data.dat"
	`define Status "../00_TB/PATTERN/p0/status.dat"
`endif

module testbed;

	reg  rst_n;
	reg  clk = 0;
	wire            dmem_we;
	wire [ 31 : 0 ] dmem_addr;
	wire [ 31 : 0 ] dmem_wdata;
	wire [ 31 : 0 ] dmem_rdata;
	wire [  2 : 0 ] riscv_status;
	wire            riscv_status_valid;
	
	// Testbench variables
	reg [2:0] expected_status_mem [0:1023];
	reg [31:0] expected_data_mem [0:2047];
	integer status_count;
	integer cycle_count;
	integer i;
	reg test_finish;
	reg [31:0] pc_core, pc_tb;

	core u_core (
		.i_clk(clk),
		.i_rst_n(rst_n),
		.o_status(riscv_status),
		.o_status_valid(riscv_status_valid),
		.o_we(dmem_we),
		.o_addr(dmem_addr),
		.o_wdata(dmem_wdata),
		.i_rdata(dmem_rdata),
		.o_pc(pc_core)  // for debugging (the pc value of current instruction
	);

	data_mem  u_data_mem (
		.i_clk(clk),
		.i_rst_n(rst_n),
		.i_we(dmem_we),
		.i_addr(dmem_addr),
		.i_wdata(dmem_wdata),
		.o_rdata(dmem_rdata)
	);

	always #(`HCYCLE) clk = ~clk;

	// Clock counter
	always @(posedge clk) begin
		if (!rst_n) begin
			cycle_count <= 0;
			pc_tb <= 0;
		end
		else begin
			cycle_count <= cycle_count + 1;
			pc_tb <= pc_core;
		end
	end

	initial begin
		$fsdbDumpfile("core.fsdb");
		$fsdbDumpvars(0, testbed, "+mda");
	end

	// Status checking at negative clock edge
	always @(negedge clk) begin
		if (!rst_n) begin
			status_count <= 0;
		end else if (rst_n && riscv_status_valid) begin
			if (riscv_status != expected_status_mem[status_count]) begin
				$display("ERROR: Status mismatch at PC %03d, at inst.dat line: %03d, at inst_assembly.dat line: %03d", pc_tb, pc_tb/4 + 1, pc_tb/4 + 8);
				$display("ERROR: Expected Status: %01d, Got: %01d", expected_status_mem[status_count], riscv_status);
				$display("ERROR: instruction (hex): 0x%08h", dmem_rdata);
				$display("ERROR: instruction (bin): %032b", dmem_rdata);
				$finish;
			end else begin
				$display("INFO: Instruction %03d status check passed at PC %03d, at inst.dat line: %03d, at inst_assembly.dat line: %03d - Status: %01d, instruction (hex): 0x%08h, instruction (bin): %032b", status_count, pc_tb, pc_tb/4 + 1, pc_tb/4 + 8, riscv_status, dmem_rdata, dmem_rdata);
			end
			
			status_count <= status_count + 1;
			
			// Check for end of file or invalid operation
			if (riscv_status == `EOF_TYPE) begin
				$display("INFO: EOF detected. Starting memory verification...");
				test_finish = 1;
				#(`CYCLE);
				verify_memory();
			end else if (riscv_status == `INVALID_TYPE) begin
				$display("INFO: Invalid operation detected. Starting memory verification...");
				test_finish = 1;
				#(`CYCLE);
				verify_memory();
			end
		end
		
		// Timeout check
		if (cycle_count >= `MAX_CYCLE) begin
			$display("ERROR: Simulation timeout after %0d cycles", `MAX_CYCLE);
			$finish;
		end
	end

	// Memory verification task
	task verify_memory;
		integer error_count;
		begin
			error_count = 0;
			$display("INFO: Verifying memory contents...");
			
			// Check data memory (lines 1025-2048 in data.dat, mapped to memory index 1024-2047)
			for (i = 1024; i < 2048; i = i + 1) begin
				if (u_data_mem.mem_r[i] !== expected_data_mem[i]) begin
					$display("ERROR: Data memory mismatch at memory index %0d (address %0d)", i, i*4);
					$display("Expected: 0x%08h, Got: 0x%08h", 
						expected_data_mem[i], u_data_mem.mem_r[i]);
					error_count = error_count + 1;
				end
			end
			
			if (error_count == 0) begin
				$display("PASS: All memory verification passed!");
				$display("INFO: Total instructions executed: %0d", status_count);
				$display("INFO: Total cycles used: %0d", cycle_count);
			end else begin
				$display("FAIL: %0d memory errors found!", error_count);
			end
			
			$finish;
		end
	endtask

	// Main test initialization
	initial begin 
		// Initialize variables
		status_count = 0;
		cycle_count = 0;
		test_finish = 0;
		
		// Load expected data
		$readmemb(`Status, expected_status_mem);
		$readmemb(`Data, expected_data_mem);
		
		// Reset sequence
		rst_n = 1;
		#(0.25 * `CYCLE) rst_n = 0;
		#(`CYCLE) rst_n = 1;
		
		// Load instructions into memory
		$readmemb(`Inst, u_data_mem.mem_r);
		
		$display("INFO: Testbench started");
		$display("INFO: Loading patterns and expected results...");
		
		// Wait for test completion or timeout
		wait(test_finish || (cycle_count >= `MAX_CYCLE));
		
		if (!test_finish) begin
			$display("ERROR: Test did not complete within cycle limit");
			$finish;
		end
	end

endmodule