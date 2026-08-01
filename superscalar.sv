module superscalar_top
(
    input logic clk,
    input logic rst
);

    //--------------------------------------------------
    // GLOBAL STALL
    //--------------------------------------------------
    logic stall;

    //--------------------------------------------------
    // PC + FETCH
    //--------------------------------------------------
    logic [31:0] pc;
    logic [31:0] pc_next;

    logic [31:0] instr1F;
    logic [31:0] instr2F;

    logic [31:0] instr1D;
    logic [31:0] instr2D;

    assign pc_next = pc + 8;

    //--------------------------------------------------
    // SIMPLE DECODE
    //--------------------------------------------------
    logic [5:0] opcode1_D;
    logic [5:0] opcode2_D;

    logic [4:0] rs1_1;
    logic [4:0] rs2_1;
    logic [4:0] rd1;

    logic [4:0] rs1_2;
    logic [4:0] rs2_2;
    logic [4:0] rd2;

    assign opcode1_D = instr1D[5:0];
    assign opcode2_D = instr2D[5:0];

    assign rs1_1 = instr1D[25:21];

    assign rs2_1 = instr1D[20:16];
    assign rd1   = instr1D[15:11];

    assign rs1_2 = instr2D[25:21];
    assign rs2_2 = instr2D[20:16];
    assign rd2   = instr2D[15:11];

    //--------------------------------------------------
    // ROB
    //--------------------------------------------------
    logic [3:0] rob_tail1;
    logic [3:0] rob_tail2;

    logic rob_full;
    logic rob_empty;

    logic commit1_en;
    logic [4:0] commit1_reg;
    logic [31:0] commit1_value;

    logic commit2_en;
    logic [4:0] commit2_reg;
    logic [31:0] commit2_value;

    logic [31:0] rob_value [0:15];
    logic        rob_valid [0:15];

    assign stall = rob_full;

    //--------------------------------------------------
    // ARF OUTPUTS
    //--------------------------------------------------
    logic [3:0] dsttag_1;
    logic [3:0] dsttag_2;

    logic        src_a1_ready;
    logic [31:0] src_a1_value;
    logic [3:0]  src_a1_tag;

    logic        src_b1_ready;
    logic [31:0] src_b1_value;
    logic [3:0]  src_b1_tag;

    logic        src_a2_ready;
    logic [31:0] src_a2_value;
    logic [3:0]  src_a2_tag;

    logic        src_b2_ready;
    logic [31:0] src_b2_value;
    logic [3:0]  src_b2_tag;

    //--------------------------------------------------
    // ID_RS OUTPUTS
    //--------------------------------------------------
    logic [5:0] rs_op1;
    logic [5:0] rs_op2;

    logic [3:0] rs_dsttag1;
    logic [3:0] rs_dsttag2;

    logic        rs_srca1_ready;
    logic [31:0] rs_srca1_value;
    logic [3:0]  rs_srca1_tag;

    logic        rs_srcb1_ready;
    logic [31:0] rs_srcb1_value;
    logic [3:0]  rs_srcb1_tag;

    logic        rs_srca2_ready;
    logic [31:0] rs_srca2_value;
    logic [3:0]  rs_srca2_tag;

    logic        rs_srcb2_ready;
    logic [31:0] rs_srcb2_value;
    logic [3:0]  rs_srcb2_tag;

    //--------------------------------------------------
    // RS ISSUE OUTPUTS
    //--------------------------------------------------
    logic [5:0]  issue1_op;
    logic [31:0] issue1_a;
    logic [31:0] issue1_b;
    logic [3:0]  issue1_tag;

    logic [5:0]  issue2_op;
    logic [31:0] issue2_a;
    logic [31:0] issue2_b;
    logic [3:0]  issue2_tag;

    //--------------------------------------------------
    // RS_EX OUTPUTS
    //--------------------------------------------------
    logic [5:0]  ex1_op;
    logic [31:0] ex1_a;
    logic [31:0] ex1_b;
    logic [3:0]  ex1_tag;

    logic [5:0]  ex2_op;
    logic [31:0] ex2_a;
    logic [31:0] ex2_b;
    logic [3:0]  ex2_tag;

    //--------------------------------------------------
    // ALU OUTPUTS
    //--------------------------------------------------
    logic        alu_valid1;
    logic [31:0] alu_result1;
    logic [3:0]  alu_tag1;

    logic        alu_valid2;
    logic [31:0] alu_result2;
    logic [3:0]  alu_tag2;

    //--------------------------------------------------
    // WB REGISTER OUTPUTS
    //--------------------------------------------------
    logic        valid_out11;
    logic [31:0] result1;
    logic [3:0]  result_tag1;

    logic        valid_out12;
    logic [31:0] result2;
    logic [3:0]  result_tag2;
    logic [31:0] pc4;
    assign pc4=pc+4;
    //--------------------------------------------------
    // PC REGISTER
    //--------------------------------------------------
    flopr #(32) PC_REG
    (
        .stallF(stall),
        .clk(clk),
        .reset(rst),
        .d(pc_next),
        .q(pc)
    );

    //--------------------------------------------------
    // IMEM
    //--------------------------------------------------
    imem IMEM
    (
        .clk(clk),
        .a1(pc[7:2]),
        .a2(pc4[7:2]),
        .rd1(instr1F),
        .rd2(instr2F)
    );

    //--------------------------------------------------
    // IF/ID
    //--------------------------------------------------
    IF_ID IF_ID_REG
    (
        .stallD(stall),
        .clk(clk),
        .instr1(instr1F),
        .instr2(instr2F),
        .instrD1(instr1D),
        .instrD2(instr2D)
    );

    //--------------------------------------------------
    // ROB
    //--------------------------------------------------
    reorder_buffer ROB
    (
        .clk(clk),
        .rst(rst),

        .alloc1(1'b1),
        .alloc2(1'b1),

        .dest_reg1(rd1),
        .dest_reg2(rd2),

        .rob_tail1(rob_tail1),
        .rob_tail2(rob_tail2),

        .wb_en1(valid_out11),
        .wb_tag1(result_tag1),
        .wb_value1(result1),

        .wb_en2(valid_out12),
        .wb_tag2(result_tag2),
        .wb_value2(result2),

        .commit1_en(commit1_en),
        .commit1_reg(commit1_reg),
        .commit1_value(commit1_value),

        .commit2_en(commit2_en),
        .commit2_reg(commit2_reg),
        .commit2_value(commit2_value),

        .rob_value(rob_value),
        .rob_valid(rob_valid),

        .full(rob_full),
        .empty(rob_empty)
    );

    //--------------------------------------------------
    // ARF
    //--------------------------------------------------
    architectural_register_file ARF
    (
        .clk(clk),
        .rst(rst),

        .dest1(1'b1),
        .dest2(1'b1),

        .dest_reg1(rd1),
        .dest_reg2(rd2),

        .rob_tail1(rob_tail1),
        .rob_tail2(rob_tail2),

        .src_a1_reg(rs1_1),
        .src_b1_reg(rs2_1),

        .src_a2_reg(rs1_2),
        .src_b2_reg(rs2_2),

        .rob_value(rob_value),
        .rob_valid(rob_valid),

        .wb_en1(commit1_en),
        .wb_reg1(commit1_reg),
        .wb_value1(commit1_value),

        .wb_en2(commit2_en),
        .wb_reg2(commit2_reg),
        .wb_value2(commit2_value),

        .dsttag_1(dsttag_1),
        .dsttag_2(dsttag_2),

        .src_a1_ready(src_a1_ready),
        .src_a1_value(src_a1_value),
        .src_a1_tag(src_a1_tag),

        .src_b1_ready(src_b1_ready),
        .src_b1_value(src_b1_value),
        .src_b1_tag(src_b1_tag),

        .src_a2_ready(src_a2_ready),
        .src_a2_value(src_a2_value),
        .src_a2_tag(src_a2_tag),

        .src_b2_ready(src_b2_ready),
        .src_b2_value(src_b2_value),
        .src_b2_tag(src_b2_tag)
    );

    //--------------------------------------------------
    // ID_RS
    //--------------------------------------------------
    ID_RS ID_RS_REG
    (
        .clk(clk),
        .stall(stall),

        .op1_in(opcode1_D),
        .op2_in(opcode2_D),

        .dsttag_1_in(dsttag_1),
        .dsttag_2_in(dsttag_2),

        .src_a1_ready_in(src_a1_ready),
        .src_a1_value_in(src_a1_value),
        .src_a1_tag_in(src_a1_tag),

        .src_b1_ready_in(src_b1_ready),
        .src_b1_value_in(src_b1_value),
        .src_b1_tag_in(src_b1_tag),

        .src_a2_ready_in(src_a2_ready),
        .src_a2_value_in(src_a2_value),
        .src_a2_tag_in(src_a2_tag),

        .src_b2_ready_in(src_b2_ready),
        .src_b2_value_in(src_b2_value),
        .src_b2_tag_in(src_b2_tag),

        .op1(rs_op1),
        .op2(rs_op2),

        .dsttag_1(rs_dsttag1),
        .dsttag_2(rs_dsttag2),

        .src_a1_ready(rs_srca1_ready),
        .src_a1_value(rs_srca1_value),
        .src_a1_tag(rs_srca1_tag),

        .src_b1_ready(rs_srcb1_ready),
        .src_b1_value(rs_srcb1_value),
        .src_b1_tag(rs_srcb1_tag),

        .src_a2_ready(rs_srca2_ready),
        .src_a2_value(rs_srca2_value),
        .src_a2_tag(rs_srca2_tag),

        .src_b2_ready(rs_srcb2_ready),
        .src_b2_value(rs_srcb2_value),
        .src_b2_tag(rs_srcb2_tag)
    );

    //--------------------------------------------------
    // RESERVATION STATION
    //--------------------------------------------------
    reservation_station RS
    (
        .clk(clk),
        .rst(rst),

        .op_code1(rs_op1),
        .src_a1(rs_srca1_value),
        .src_b1(rs_srcb1_value),
        .ready_a1(rs_srca1_ready),
        .ready_b1(rs_srcb1_ready),
        .tag_a1(rs_srca1_tag),
        .tag_b1(rs_srcb1_tag),
        .dest_tag1(rs_dsttag1),

        .op_code2(rs_op2),
        .src_a2(rs_srca2_value),
        .src_b2(rs_srcb2_value),
        .ready_a2(rs_srca2_ready),
        .ready_b2(rs_srcb2_ready),
        .tag_a2(rs_srca2_tag),
        .tag_b2(rs_srcb2_tag),
        .dest_tag2(rs_dsttag2),

        .wb_en1(alu_valid1),
		.wb_tag1(alu_tag1),
		.wb_value1(alu_result1),

		.wb_en2(alu_valid2),
		.wb_tag2(alu_tag2),
		.wb_value2(alu_result2),

        .issue1_op(issue1_op),
        .issue1_a(issue1_a),
        .issue1_b(issue1_b),
        .issue1_tag(issue1_tag),

        .issue2_op(issue2_op),
        .issue2_a(issue2_a),
        .issue2_b(issue2_b),
        .issue2_tag(issue2_tag)
    );

    //--------------------------------------------------
    // RS_EX
    //--------------------------------------------------
    RS_EX RS_EX_REG
    (
        .clk(clk),
        .stall(stall),

        .issue1_op_in(issue1_op),
        .issue1_a_in(issue1_a),
        .issue1_b_in(issue1_b),
        .issue1_tag_in(issue1_tag),

        .issue2_op_in(issue2_op),
        .issue2_a_in(issue2_a),
        .issue2_b_in(issue2_b),
        .issue2_tag_in(issue2_tag),

        .issue1_op(ex1_op),
        .issue1_a(ex1_a),
        .issue1_b(ex1_b),
        .issue1_tag(ex1_tag),

        .issue2_op(ex2_op),
        .issue2_a(ex2_a),
        .issue2_b(ex2_b),
        .issue2_tag(ex2_tag)
    );

    //--------------------------------------------------
    // ALU1
    //--------------------------------------------------
    alu ALU1
    (
        .clk(clk),
        .rst(rst),

        .op_code(ex1_op),
        .src_a(ex1_a),
        .src_b(ex1_b),
        .dest_tag(ex1_tag),

        .valid_out(alu_valid1),
        .result(alu_result1),
        .result_tag(alu_tag1)
    );

    //--------------------------------------------------
    // ALU2
    //--------------------------------------------------
    alu ALU2
    (
        .clk(clk),
        .rst(rst),

        .op_code(ex2_op),
        .src_a(ex2_a),
        .src_b(ex2_b),
        .dest_tag(ex2_tag),

        .valid_out(alu_valid2),
        .result(alu_result2),
        .result_tag(alu_tag2)
    );

    //--------------------------------------------------
    // RS_WB
    //--------------------------------------------------
    RS_WB WB_REG
    (
        .clk(clk),
        .stall(stall),

        .valid_out11_in(alu_valid1),
        .result1_in(alu_result1),
        .result_tag1_in(alu_tag1),

        .valid_out12_in(alu_valid2),
        .result2_in(alu_result2),
        .result_tag2_in(alu_tag2),

        .valid_out11(valid_out11),
        .result1(result1),
        .result_tag1(result_tag1),

        .valid_out12(valid_out12),
        .result2(result2),
        .result_tag2(result_tag2)
    );

endmodule



module imem(input clk, 
            input  logic [5:0] a1,a2,
            output logic [31:0] rd1,rd2
	    );

  logic [31:0] RAM[63:0];
  logic [4:0] count =5'b0;
  
  //always_ff @(a) $display("pc: %h", a);

  initial
      $readmemh("memfile.dat",RAM,0,3);

		
	always @(posedge clk)
	begin
//		rd = RAM[a];
		count = count+1;
		$display("Clock cycle: %d", count);
		
	end
	
  assign rd1 = RAM[a1]; // word aligned
  assign rd2 = RAM[a2];

  always @(rd1 or rd2) 
  begin
  if(rd1!=8'hx)
  $display("Fetched instruction %h", rd1);
  if(rd2!=8'hx)
  $display("Fetched instruction %h", rd2);
  end
endmodule


module flopr #(parameter WIDTH = 32)
              (input logic stallF,
	       input  logic  clk, reset,
               input  logic [WIDTH-1:0] d, 
               output logic [WIDTH-1:0] q
	       );

  always_ff @(posedge clk, posedge reset)
    if (reset) q <= 0;
//    else if ((stallF==1'b0)||(stallF==1'bx))   q <= d; 
	 else 
	 begin
		case(stallF)
			1'b0 : q<=d;
			1'bx : q<=d;
		endcase
	 end
	 
endmodule

module IF_ID(
              input logic stallD,
	      input logic clk,
	      input logic [31:0] instr1,instr2, 
	       output logic [31:0] instrD1,instrD2
	       );
		always @(posedge clk)
		begin
			//$display("stallD=%b", stallD);
			//1'bx must be in case and not if-else!
			//if ((stallD==1'b0)||(stallD==1'bx))  <= EQUALITY FOR DONT CARE DOESNT WORK
				case(stallD)
					1'bx:
					begin
						instrD1 <= instr1;
						instrD2 <= instr2;
					end
					1'b0:
					begin
						instrD1 <= instr1;
						instrD2 <= instr2;
					end
					
				endcase
			end
//			if ((stallD==1'b0)||(stallD==1'bx)) 
//			begin
//				//$display("IF to ID");
//				instrD <= instr;
//				pcplus4D <= pcplus4;
//				if(instrD!=8'hx)
//				$display("Instruction %h is in ID stage", instrD);
//				//$display("pcplus4D: %h", pcplus4D);
//			end
endmodule

module reorder_buffer #(parameter SIZE = 16)
(
    input  logic        clk,
    input  logic        rst,

    //-----------------------------------------
    // DISPATCH
    //-----------------------------------------
    input  logic        alloc1,
    input  logic        alloc2,

    input  logic [4:0]  dest_reg1,
    input  logic [4:0]  dest_reg2,

    output logic [3:0]  rob_tail1,
    output logic [3:0]  rob_tail2,

    //-----------------------------------------
    // WRITEBACK
    //-----------------------------------------
    input  logic        wb_en1,
    input  logic [3:0]  wb_tag1,
    input  logic [31:0] wb_value1,

    input  logic        wb_en2,
    input  logic [3:0]  wb_tag2,
    input  logic [31:0] wb_value2,

    //-----------------------------------------
    // COMMIT
    //-----------------------------------------
    output logic        commit1_en,
    output logic [4:0]  commit1_reg,
    output logic [31:0] commit1_value,

    output logic        commit2_en,
    output logic [4:0]  commit2_reg,
    output logic [31:0] commit2_value,

    //-----------------------------------------
    // ROB → ARF
    //-----------------------------------------
    output logic [31:0] rob_value [0:SIZE-1],
    output logic        rob_valid [0:SIZE-1],

    //-----------------------------------------
    // STATUS
    //-----------------------------------------
    output logic        full,
    output logic        empty
);
    assign valid1 =(dest_reg1 >= 0 && dest_reg1 <= 31); 
    assign valid2 =(dest_reg2 >= 0 && dest_reg2 <= 31);
 
    //-----------------------------------------
    // STORAGE
    //-----------------------------------------
    logic [4:0]  dest_reg [0:SIZE-1];
    logic        busy     [0:SIZE-1];

    logic [$clog2(SIZE)-1:0] head;
    logic [$clog2(SIZE)-1:0] tail;

    logic [$clog2(SIZE+1)-1:0] count;

    //-----------------------------------------
    // NEXT STATE
    //-----------------------------------------
    logic [$clog2(SIZE)-1:0] next_head;
    logic [$clog2(SIZE)-1:0] next_tail;

    logic [$clog2(SIZE+1)-1:0] next_count;

    integer i;

    //-----------------------------------------
    // STATUS
    //-----------------------------------------
    assign full  = (count >= SIZE-2);
    assign empty = (count == 0);

    //-----------------------------------------
    // TAGS
    //-----------------------------------------
    assign rob_tail1 = tail%SIZE;
    assign rob_tail2 = (tail + 1) % SIZE;

    //-----------------------------------------
    // SEQUENTIAL
    //-----------------------------------------
    always @(posedge clk or posedge rst)
    begin
        if (rst)
        begin
            head  <= 0;
            tail  <= 0;
            count <= 0;

            commit1_en <= 0;
            commit2_en <= 0;

            for(i=0;i<SIZE;i=i+1)
            begin
                rob_valid[i] <= 0;
                busy[i]      <= 0;
                rob_value[i] <= 0;
                dest_reg[i]  <= 0;
            end
        end
        else
        begin

            //---------------------------------
            // DEFAULTS
            //---------------------------------
            commit1_en <= 1'b0;
            commit2_en <= 1'b0;

            next_head  = head;
            next_tail  = tail;
            next_count = count;

            //---------------------------------
            // WRITEBACK
            //---------------------------------
            if (wb_en1)
            begin
                rob_value[wb_tag1] = wb_value1;
                rob_valid[wb_tag1] = 1'b1;
            end

            if (wb_en2)
            begin
                rob_value[wb_tag2] = wb_value2;
                rob_valid[wb_tag2] = 1'b1;
            end


	     //---------------------------------
            // DISPLAY ROB AFTER WRITEBACK
            //---------------------------------
            $display("\n========== ROB TABLE ==========");
            $display("HEAD=%0d TAIL=%0d COUNT=%0d", head, tail, count);
            $display("---------------------------------------------------");
            $display("IDX | BUSY | VALID | DEST | VALUE");
            $display("---------------------------------------------------");

            for(i=0;i<SIZE;i=i+1)
            begin
                $display("%0d   |   %0b   |   %0b   |  R%0d  | %0d",
                         i,
                         busy[i],
                         rob_valid[i],
                         dest_reg[i],
                         rob_value[i]);
            end

            $display("===================================================\n");

            //---------------------------------
            // COMMIT 1
            //---------------------------------
            if (!empty && rob_valid[next_head])
            begin
                commit1_en    <= 1'b1;
                commit1_reg   <= dest_reg[next_head];
                commit1_value <= rob_value[next_head];

                rob_valid[next_head] <= 1'b0;
                busy[next_head]      <= 1'b0;

                next_head  = (next_head + 1) % SIZE;
                next_count = next_count - 1;

                //---------------------------------
                // COMMIT 2
                //---------------------------------
                if ((next_count > 0) && rob_valid[next_head])
                begin
                    commit2_en    <= 1'b1;
                    commit2_reg   <= dest_reg[next_head];
                    commit2_value <= rob_value[next_head];

                    rob_valid[next_head] <= 1'b0;
                    busy[next_head]      <= 1'b0;

                    next_head  = (next_head + 1) % SIZE;
                    next_count = next_count - 1;
                end
            end

            //---------------------------------
            // ALLOC 1
            //---------------------------------
            if (valid1 && (next_count < SIZE))
            begin
                dest_reg[next_tail]  <= dest_reg1;
                busy[next_tail]      <= 1'b1;
                rob_valid[next_tail] <= 1'b0;

                next_tail  = (next_tail + 1) % SIZE;
                next_count = next_count + 1;
            end

            //---------------------------------
            // ALLOC 2
            //---------------------------------
            if (valid2 && (next_count < SIZE))
            begin
                dest_reg[next_tail]  <= dest_reg2;
                busy[next_tail]      <= 1'b1;
                rob_valid[next_tail] <= 1'b0;

                next_tail  = (next_tail + 1) % SIZE;
                next_count = next_count + 1;
            end

            //---------------------------------
            // UPDATE STATE
            //---------------------------------
            head  <= next_head;
            tail  <= next_tail;
            count <= next_count;

        end
    end

endmodule


//               ---------------------------------------------------------------------------------------  


module architectural_register_file 
(
    input  logic        clk,
    input  logic        rst,

    //-----------------------------------------
    // SOURCE REGISTERS
    //-----------------------------------------
    input  logic [4:0]  src_a1_reg,
    input  logic [4:0]  src_b1_reg,

    input  logic [4:0]  src_a2_reg,
    input  logic [4:0]  src_b2_reg,

    //-----------------------------------------
    // DESTINATION REGISTERS
    //-----------------------------------------
    input  logic        dest1,
    input  logic        dest2,

    input  logic [4:0]  dest_reg1,
    input  logic [4:0]  dest_reg2,

    //-----------------------------------------
    // ROB TAG INPUTS
    //-----------------------------------------
    input  logic [3:0]  rob_tail1,
    input  logic [3:0]  rob_tail2,

    //-----------------------------------------
    // WRITEBACK
    //-----------------------------------------
    input  logic        wb_en1,
    input  logic [4:0]  wb_reg1,
    input  logic [31:0] wb_value1,

    input  logic        wb_en2,
    input  logic [4:0]  wb_reg2,
    input  logic [31:0] wb_value2,

    //-----------------------------------------
    // ROB BYPASS
    //-----------------------------------------
    input  logic [31:0] rob_value [0:15],
    input  logic        rob_valid [0:15],

    //-----------------------------------------
    // OUTPUTS : INST1
    //-----------------------------------------
    output logic        src_a1_ready,
    output logic [31:0] src_a1_value,
    output logic [3:0]  src_a1_tag,

    output logic        src_b1_ready,
    output logic [31:0] src_b1_value,
    output logic [3:0]  src_b1_tag,

    //-----------------------------------------
    // OUTPUTS : INST2
    //-----------------------------------------
    output logic        src_a2_ready,
    output logic [31:0] src_a2_value,
    output logic [3:0]  src_a2_tag,

    output logic        src_b2_ready,
    output logic [31:0] src_b2_value,
    output logic [3:0]  src_b2_tag,

    //-----------------------------------------
    // DEST TAG OUTPUTS
    //-----------------------------------------
    output logic [3:0] dsttag_1,
    output logic [3:0] dsttag_2
);

    //-----------------------------------------
    // ARF STORAGE
    //-----------------------------------------
    logic [31:0] data [0:31];
    logic        busy [0:31];
    logic [3:0]  tag  [0:31];

    //-----------------------------------------
    // INTERNALS
    //-----------------------------------------
    integer i;
    integer c = 0;

    logic valid1;
    logic valid2;

    assign valid1 = (dest_reg1 <= 31);
    assign valid2 = (dest_reg2 <= 31);

    //-----------------------------------------
    // OPERAND READ TASK
    //-----------------------------------------
    task automatic read_operand(
        input  logic [4:0]  reg1,
        output logic        ready,
        output logic [31:0] value,
        output logic [3:0]  tag_out
    );
    begin

        if (!busy[reg1])
        begin
            ready   = 1'b1;
            value   = data[reg1];
            tag_out = 4'd0;
        end
        else
        begin
            tag_out = tag[reg1];

            if (rob_valid[tag[reg1]])
            begin
                ready = 1'b1;
                value = rob_value[tag[reg1]];
            end
            else
            begin
                ready = 1'b0;
                value = 32'd0;
            end
        end

    end
    endtask

    //-----------------------------------------
    // SEQUENTIAL
    //-----------------------------------------
    always @(negedge clk)
    begin

        c <= c + 1;

        //-------------------------------------
        // RESET
        //-------------------------------------
        if (rst)
        begin

            for(i=0;i<32;i=i+1)
            begin
                busy[i] <= 1'b0;
                data[i] <= i;
                tag[i]  <= 4'd0;
            end

            dsttag_1 <= 0;
            dsttag_2 <= 0;

        end

        //-------------------------------------
        // NORMAL OPERATION
        //-------------------------------------
        else if (c > 0)
        begin

            //---------------------------------
            // WRITEBACK PORT 1
            //---------------------------------
            if (wb_en1)
            begin
                    busy[wb_reg1] <= 1'b0;
                    data[wb_reg1] <= wb_value1;
            end

            //---------------------------------
            // WRITEBACK PORT 2
            //---------------------------------
            if (wb_en2)
            begin
                    busy[wb_reg2] <= 1'b0;
                    data[wb_reg2] <= wb_value2;
            end

            //---------------------------------
            // OPERAND READS
            //---------------------------------
            read_operand(src_a1_reg,
                         src_a1_ready,
                         src_a1_value,
                         src_a1_tag);

            read_operand(src_b1_reg,
                         src_b1_ready,
                         src_b1_value,
                         src_b1_tag);
	    
	     if (dest1 && valid1)
            begin
                busy[dest_reg1] = 1'b1;
                tag[dest_reg1]  = rob_tail1;
                dsttag_1        = rob_tail1;
            end

            read_operand(src_a2_reg,
                         src_a2_ready,
                         src_a2_value,
                         src_a2_tag);

            read_operand(src_b2_reg,
                         src_b2_ready,
                         src_b2_value,
                         src_b2_tag);

            //---------------------------------
            // DESTINATION ALLOCATION
            //---------------------------------
           

            if (dest2 && valid2)
            begin
                busy[dest_reg2] <= 1'b1;
                tag[dest_reg2]  <= rob_tail2;
                dsttag_2        <= rob_tail2;
            end

            //---------------------------------
            // DISPLAY ARF
            //---------------------------------
            $display("\n=============== ARF TABLE ===============");
            $display("-----------------------------------------");
            $display("REG | BUSY | TAG | DATA");
            $display("-----------------------------------------");

            for(i=0;i<32;i=i+1)
            begin
                $display("R%0d  |   %0b   |  %0d  | %0d",
                         i,
                         busy[i],
                         tag[i],
                         data[i]);
            end

            $display("=========================================\n");

        end

    end

endmodule

module alu
(
    input  logic clk,
    input  logic rst,

    //-----------------------------------------
    // INPUT
    //-----------------------------------------
    input  logic [5:0]  op_code,
    input  logic [31:0] src_a,
    input  logic [31:0] src_b,
    input  logic [3:0]  dest_tag,

    //-----------------------------------------
    // OUTPUT
    //-----------------------------------------
    output logic        valid_out,
    output logic [31:0] result,
    output logic [3:0]  result_tag
);

    logic [31:0] res;

    //-----------------------------------------
    // COMBINATIONAL EXECUTION
    //-----------------------------------------
    always @(*)
begin
    valid_out = 1'b1;

    case (op_code)

        6'h20: res = src_a + src_b;   // ADD
        6'h22: res = src_a - src_b;   // SUB
        6'h24: res = src_a & src_b;   // AND
        6'h25: res = src_a | src_b;   // OR
        6'h26: res = src_a ^ src_b;   // XOR
        6'h2A: res = (src_a < src_b); // SLT

        6'h18: res = src_a * src_b;   // MUL
        6'h1A: res = (src_b != 0) ? src_a / src_b : 32'd0; // DIV

        default:
        begin
            res       = 32'b0;
            valid_out = 1'b0;
        end

    endcase
end
        assign    result     = res;
        assign    result_tag = dest_tag;

endmodule


module reservation_station #(parameter SIZE = 16)
(
    input  logic clk,
    input  logic rst,

    //-----------------------------------------
    // INPUT: 2 instructions
    //-----------------------------------------
    input  logic [5:0]  op_code1,
    input  logic [31:0] src_a1,
    input  logic [31:0] src_b1,
    input  logic        ready_a1,
    input  logic        ready_b1,
    input  logic [3:0]  tag_a1,
    input  logic [3:0]  tag_b1,
    input  logic [3:0]  dest_tag1,

    input  logic [5:0]  op_code2,
    input  logic [31:0] src_a2,
    input  logic [31:0] src_b2,
    input  logic        ready_a2,
    input  logic        ready_b2,
    input  logic [3:0]  tag_a2,
    input  logic [3:0]  tag_b2,
    input  logic [3:0]  dest_tag2,

    //-----------------------------------------
    // WRITEBACK (2 ports)
    //-----------------------------------------
    input  logic        wb_en1,
    input  logic [3:0]  wb_tag1,
    input  logic [31:0] wb_value1,

    input  logic        wb_en2,
    input  logic [3:0]  wb_tag2,
    input  logic [31:0] wb_value2,

    //-----------------------------------------
    // OUTPUT: 2 issued instructions
    //-----------------------------------------
    output logic [5:0]  issue1_op,
    output logic [31:0] issue1_a,
    output logic [31:0] issue1_b,
    output logic [3:0]  issue1_tag,
    output logic        issue1_valid,
    output logic [5:0]  issue2_op,
    output logic [31:0] issue2_a,
    output logic [31:0] issue2_b,
    output logic [3:0]  issue2_tag,
    output logic        issue2_valid
);

    //-----------------------------------------
    // INTERNAL VALID GENERATION
    // 111111 = INVALID / NOP
    //-----------------------------------------
    logic valid1;
    logic valid2;

    assign valid1 = (op_code1 != 6'b111111);
    assign valid2 = (op_code2 != 6'b111111);

    //-----------------------------------------
    // STORAGE
    //-----------------------------------------
    logic        busy [0:SIZE-1];

    logic [5:0]  op_code [0:SIZE-1];

    logic [31:0] src_a   [0:SIZE-1];
    logic [31:0] src_b   [0:SIZE-1];

    logic [3:0]  tag_a   [0:SIZE-1];
    logic [3:0]  tag_b   [0:SIZE-1];

    logic        ready_a [0:SIZE-1];
    logic        ready_b [0:SIZE-1];

    logic [3:0]  dest_tag [0:SIZE-1];

    //-----------------------------------------
    // ISSUE POINTERS
    //-----------------------------------------
    integer first;
    integer second;

    //-----------------------------------------
    // TEMP FREE SLOT POINTERS
    //-----------------------------------------
    integer f1;
    integer f2;

    integer i;

    //-----------------------------------------
    // MAIN LOGIC
    //-----------------------------------------
    always_ff @(posedge clk)
    begin

        if (rst)
        begin
            for (i = 0; i < SIZE; i = i + 1)
            begin
                busy[i] <= 0;
            end
        end

        else
        begin

            //---------------------------------
            // WAKEUP LOGIC
            //---------------------------------
            for (i = 0; i < SIZE; i = i + 1)
            begin

                if (busy[i])
                begin

                    //---------------------------------
                    // WRITEBACK PORT 1
                    //---------------------------------
                    if (!ready_a[i] &&
                        wb_en1 &&
                        (tag_a[i] == wb_tag1))
                    begin
                        src_a[i]   = wb_value1;
                        ready_a[i] = 1;
                    end

                    if (!ready_b[i] &&
                        wb_en1 &&
                        (tag_b[i] == wb_tag1))
                    begin
                        src_b[i]   = wb_value1;
                        ready_b[i] = 1;
                    end

                    //---------------------------------
                    // WRITEBACK PORT 2
                    //---------------------------------
                    if (!ready_a[i] &&
                        wb_en2 &&
                        (tag_a[i] == wb_tag2))
                    begin
                        src_a[i]   = wb_value2;
                        ready_a[i] = 1;
                    end

                    if (!ready_b[i] &&
                        wb_en2 &&
                        (tag_b[i] == wb_tag2))
                    begin
                        src_b[i]   = wb_value2;
                        ready_b[i] = 1;
                    end

                end
            end

            //---------------------------------
            // CLEAR ISSUED ENTRIES
            //---------------------------------
            if (first != -1)
                busy[first] <= 0;

            if (second != -1)
                busy[second] <= 0;

            //---------------------------------
            // FIND FREE SLOTS
            //---------------------------------
            f1 = -1;
            f2 = -1;

            for (i = 0; i < SIZE; i = i + 1)
            begin

                if (
                    !busy[i] ||
                    (i == first) ||
                    (i == second)
                   )
                begin

                    if (f1 == -1)
                        f1 = i;

                    else if (f2 == -1)
                        f2 = i;

                end
            end

            //---------------------------------
            // INSERT INSTRUCTION 1
            //---------------------------------
            if (valid1 && (f1 != -1))
            begin

                busy[f1] <= 1;

                op_code[f1] <= op_code1;

                src_a[f1] <= src_a1;
                src_b[f1] <= src_b1;

                tag_a[f1] <= tag_a1;
                tag_b[f1] <= tag_b1;

                ready_a[f1] <= ready_a1;
                ready_b[f1] <= ready_b1;

                dest_tag[f1] <= dest_tag1;

            end

            //---------------------------------
            // INSERT INSTRUCTION 2
            //---------------------------------
            if (valid2 && (f2 != -1))
            begin

                busy[f2] <= 1;

                op_code[f2] <= op_code2;

                src_a[f2] <= src_a2;
                src_b[f2] <= src_b2;

                tag_a[f2] <= tag_a2;
                tag_b[f2] <= tag_b2;

                ready_a[f2] <= ready_a2;
                ready_b[f2] <= ready_b2;

                dest_tag[f2] <= dest_tag2;

            end

        end
    end

    //-----------------------------------------
    // ISSUE LOGIC
    //-----------------------------------------
    always@(*)
    begin

        first  = -1;
        second = -1;

       //---------------------------------
// FIND FIRST READY
//---------------------------------
for (int j = 0; j < SIZE; j = j + 1)
begin

    if (
        (first == -1) &&
        busy[j] &&
        ready_a[j] &&
        ready_b[j]
       )
    begin
        first = j;
    end

end 
       //---------------------------------
// FIND SECOND READY
//---------------------------------
for (int j = 0; j < SIZE; j = j + 1)
begin

    if (
        (j != first) &&
        (second == -1) &&
        busy[j] &&
        ready_a[j] &&
        ready_b[j]
       )
    begin
        second = j;
    end

end

        //---------------------------------
        // DEFAULT OUTPUTS
        //---------------------------------
        issue1_op    = 0;
        issue1_a     = 0;
        issue1_b     = 0;
        issue1_tag   = 0;
        issue1_valid = 0;

        issue2_op    = 0;
        issue2_a     = 0;
        issue2_b     = 0;
        issue2_tag   = 0;
        issue2_valid = 0;

        //---------------------------------
        // ISSUE 1
        //---------------------------------
        if (first != -1)
        begin

            issue1_op    = op_code[first];
            issue1_a     = src_a[first];
            issue1_b     = src_b[first];
            issue1_tag   = dest_tag[first];
            issue1_valid = 1;

        end

        //---------------------------------
        // ISSUE 2
        //---------------------------------
        if (second != -1)
        begin

            issue2_op    = op_code[second];
            issue2_a     = src_a[second];
            issue2_b     = src_b[second];
            issue2_tag   = dest_tag[second];
            issue2_valid = 1;

        end

    end

endmodule




module ID_RS(
    input  logic        clk,
    input  logic        stall,
    
    input  logic [5:0]  op1_in,
    input  logic [5:0]  op2_in,
    
    input  logic [3:0]  dsttag_1_in,
    input  logic [3:0]  dsttag_2_in,

    input  logic        src_a1_ready_in,
    input  logic [31:0] src_a1_value_in,
    input  logic [3:0]  src_a1_tag_in,

    input  logic        src_b1_ready_in,
    input  logic [31:0] src_b1_value_in,
    input  logic [3:0]  src_b1_tag_in,

    input  logic        src_a2_ready_in,
    input  logic [31:0] src_a2_value_in,
    input  logic [3:0]  src_a2_tag_in,

    input  logic        src_b2_ready_in,
    input  logic [31:0] src_b2_value_in,
    input  logic [3:0]  src_b2_tag_in,
    
    output logic [5:0]  op1,
    output logic [5:0]  op2,
    
    output logic [3:0]  dsttag_1,
    output logic [3:0]  dsttag_2,

    output logic        src_a1_ready,
    output logic [31:0] src_a1_value,
    output logic [3:0]  src_a1_tag,

    output logic        src_b1_ready,
    output logic [31:0] src_b1_value,
    output logic [3:0]  src_b1_tag,

    output logic        src_a2_ready,
    output logic [31:0] src_a2_value,
    output logic [3:0]  src_a2_tag,

    output logic        src_b2_ready,
    output logic [31:0] src_b2_value,
    output logic [3:0]  src_b2_tag
);

always_ff @(posedge clk)
begin
    if (stall!=1)
    begin
	op1      <= op1_in;
    	op2      <= op2_in;
        dsttag_1 <= dsttag_1_in;
        dsttag_2 <= dsttag_2_in;

        src_a1_ready <= src_a1_ready_in;
        src_a1_value <= src_a1_value_in;
        src_a1_tag   <= src_a1_tag_in;

        src_b1_ready <= src_b1_ready_in;
        src_b1_value <= src_b1_value_in;
        src_b1_tag   <= src_b1_tag_in;

        src_a2_ready <= src_a2_ready_in;
        src_a2_value <= src_a2_value_in;
        src_a2_tag   <= src_a2_tag_in;

        src_b2_ready <= src_b2_ready_in;
        src_b2_value <= src_b2_value_in;
        src_b2_tag   <= src_b2_tag_in;
    end
end

endmodule






module RS_EX
(
    input  logic        clk,
    input  logic        stall,

    input  logic [5:0]  issue1_op_in,
    input  logic [31:0] issue1_a_in,
    input  logic [31:0] issue1_b_in,
    input  logic [3:0]  issue1_tag_in,

    input  logic [5:0]  issue2_op_in,
    input  logic [31:0] issue2_a_in,
    input  logic [31:0] issue2_b_in,
    input  logic [3:0]  issue2_tag_in,

    output logic [5:0]  issue1_op,
    output logic [31:0] issue1_a,
    output logic [31:0] issue1_b,
    output logic [3:0]  issue1_tag,

    output logic [5:0]  issue2_op,
    output logic [31:0] issue2_a,
    output logic [31:0] issue2_b,
    output logic [3:0]  issue2_tag
);

always_ff @(posedge clk)
begin
    if (stall!=1)
    begin
        issue1_op  <= issue1_op_in;
        issue1_a   <= issue1_a_in;
        issue1_b   <= issue1_b_in;
        issue1_tag <= issue1_tag_in;

        issue2_op  <= issue2_op_in;
        issue2_a   <= issue2_a_in;
        issue2_b   <= issue2_b_in;
        issue2_tag <= issue2_tag_in;
    end
end

endmodule




module RS_WB
(
    input  logic        clk,
    input  logic        stall,

    input  logic        valid_out11_in,
    input  logic [31:0] result1_in,
    input  logic [3:0]  result_tag1_in,

    input  logic        valid_out12_in,
    input  logic [31:0] result2_in,
    input  logic [3:0]  result_tag2_in,

    output logic        valid_out11,
    output logic [31:0] result1,
    output logic [3:0]  result_tag1,

    output logic        valid_out12,
    output logic [31:0] result2,
    output logic [3:0]  result_tag2
);

always_ff @(posedge clk)
begin
    if (!stall)
    begin
        valid_out11 <= valid_out11_in;
        result1     <= result1_in;
        result_tag1 <= result_tag1_in;

        valid_out12 <= valid_out12_in;
        result2     <= result2_in;
        result_tag2 <= result_tag2_in;
    end
end

endmodule
