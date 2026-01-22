module cpu (
	input wire clk,
	input wire rst,
);

reg [31:0] regs [0:31];
reg [31:0] pc;

localparam FETCH = 0;
localparam DECODE = 1;
localparam EXEC = 2;
localparam IDLE = 3;

localparam INSTR_SIZE = 32;

localparam TYPE_I_OPCODE = 7'b0010011;
localparam TYPE_S_OPCODE = 7'b0100011;
localparam TYPE_R_OPCODE = 7'b0110011;
localparam TYPE_B_OPCODE = 7'b1100011;
localparam TYPE_J_OPCODE = 7'b1101111;
localparam TYPE_LUI_OPCODE = 7'b0110111;
localparam TYPE_AUIPC_OPCODE = 7'b0010111;

localparam ADDI_FN3 = 3'b000;
localparam SLTI_FN3 = 3'b010;
localparam SLTIU_FN3 = 3'b011;
localparam XORI_FN3 = 3'b100;
localparam ORI_FN3 = 3'b110;
localparam ANDI_FN3 = 3'b111;

localparam ADD_FN3 = 3'b000;
localparam SUB_FN3 = 3'b000;
localparam SLL_FN3 = 3'b001;
localparam SRL_FN3 = 3'b101;
localparam SRA_FN3 = 3'b101;
localparam OR_FN3 = 3'b110;
localparam XOR_FN3 = 3'b100;

localparam BEQ_FN3 = 3'b000;
localparam BNE_FN3 = 3'b001;
localparam BLT_FN3 = 3'b100;
localparam BLTU_FN3 = 3'b110;
localparam BGE_FN3 = 3'b101;
localparam BGEU_FN3 = 3'b111;

localparam ADD_FN7 = 7'b0000000;
localparam SUB_FN7 = 7'b0100000;
localparam SLL_FN7 = 7'b0000000;
localparam SRL_FN7 = 7'b0000000;
localparam SRA_FN7 = 7'b0100000;
localparam OR_FN7 =  7'b0000000;
localparam XOR_FN7 = 7'b0000000;

localparam TYPE_I = 2'h14;
localparam TYPE_S = 2'h15;
localparam TYPE_R = 2'h16;
localparam TYPE_B = 2'h17;
localparam TYPE_J = 2'h18;
localparam TYPE_LUI = 2'h19;
localparam TYPE_AUIPC = 2'h20;

localparam NOTHING = 3'h100;

localparam X0_OPCODE  = 5'b00000;
localparam X1_OPCODE  = 5'b00001;
localparam X2_OPCODE  = 5'b00010;
localparam X3_OPCODE  = 5'b00011;
localparam X4_OPCODE  = 5'b00100;
localparam X5_OPCODE  = 5'b00101;
localparam X6_OPCODE  = 5'b00110;
localparam X7_OPCODE  = 5'b00111;
localparam X8_OPCODE  = 5'b01000;
localparam X9_OPCODE  = 5'b01001;
localparam X10_OPCODE = 5'b01010;
localparam X11_OPCODE = 5'b01011;
localparam X12_OPCODE = 5'b01100;
localparam X13_OPCODE = 5'b01101;
localparam X14_OPCODE = 5'b01110;
localparam X15_OPCODE = 5'b01111;
localparam X16_OPCODE = 5'b10000;
localparam X17_OPCODE = 5'b10001;
localparam X18_OPCODE = 5'b10010;
localparam X19_OPCODE = 5'b10011;
localparam X20_OPCODE = 5'b10100;
localparam X21_OPCODE = 5'b10101;
localparam X22_OPCODE = 5'b10110;
localparam X23_OPCODE = 5'b10111;
localparam X24_OPCODE = 5'b11000;
localparam X25_OPCODE = 5'b11001;
localparam X26_OPCODE = 5'b11010;
localparam X27_OPCODE = 5'b11011;
localparam X28_OPCODE = 5'b11100;
localparam X29_OPCODE = 5'b11101;
localparam X30_OPCODE = 5'b11110;
localparam X31_OPCODE = 5'b11111;

parameter COUNT_RAM_WORD = 1024;
parameter SIZE_WORD		 = 32;

reg [2:0] current_instr_class;

wire [6:0] 		opcode;
wire [4:0] 		rd;
wire [1:0] 		funct3;
wire [4:0] 		rs1;
wire [4:0] 		rs2;
wire [6:0] 		funct7;
wire [11:0] 	i_type_imm;
wire [4:0] 		s_type_imm;
wire [6:0] 		s_type_imm2;
wire [19:0] 	u_type_imm;
wire [4:0] 		b_type_imm;
wire [6:0] 		b_type_imm2;
wire [8:0] 		j_type_imm;
wire [11:0] 	j_type_imm2;

reg [1:0] current_state;
reg [SIZE_WORD-1:0] ram [0:COUNT_RAM_WORD-1];
reg [INSTR_SIZE-1:0] instr;

always @ (posedge clk or posedge rst) begin
	if (rst) begin
		pc <= 0;
		integer i;
		for (i = 0; i < COUNT_RAM_WORD; i = i + 1) begin
			regs[i] <= 'b0;
		end
		current_state <= IDLE;
		current_instr_class <= NOTHING;
		instr <= 0;

	end else begin
		case (current_state)
		FETCH: begin
			instr <= ram[pc >> 2];
			current_state <= DECODE;	
		end

		DECODE: begin
			opcode <= instr[6:0];
			case (opcode)
			TYPE_I_OPCODE: begin
				rd <= instr[11:7];
				funct3 <= instr[14:12];
				rs1 <= instr[19:15];
				i_type_imm  <= instr[31:20];
				current_instr_class <= TYPE_I;
				current_state <= EXEC;
			end
			TYPE_B_OPCODE: begin
				b_type_imm <= instr[11:7];
				funct3 <= instr[14:12];
				rs1 <= instr[19:15];
				rs2 <= instr[24:20];
				b_type_imm2 <= instr[31:25];
				current_instr_class <= TYPE_B;
				current_state <= EXEC;
			end
			TYPE_J_OPCODE: begin
				rd <= instr[11:7];
				j_type_imm <= instr[20:12];
				j_type_imm2 <= instr[31:21];
				current_instr_class <= TYPE_J;
				current_state <= EXEC;
			end
			TYPE_R_OPCODE: begin
				rd <= instr[11:7];
				funct3 <= instr[14:12];
				rs <= instr[19:15];
				rs2 <= instr[24:20];
				funct7 <= instr[31:25];
				current_instr_class <= TYPE_R;
				current_state <= EXEC;
			end
			TYPE_S_OPCODE: begin
				s_type_imm <= instr[11:7];
				funct3 <= instr[14:12];
				rs <= instr[19:15];
				rs2 <= instr[24:20];
				s_type_imm2 <= instr[31:25];
				current_instr_state <= TYPE_S;
				current_state <= EXEC;
			end
			TYPE_LUI_OPCODE: begin
				rd <= instr[11:7];
				u_type_imm <= instr[31:12];
				current_instr_class <= TYPE_LUI;
				current_state <= EXEC;
			end
			TYPE_AUIPC_OPCODE: begin
				rd <= instr[11:7];
				u_type_imm <= instr[31:12];
				current_instr_class <= TYPE_AUIPC;
				current_state <= EXEC;
			end
			endcase
		end

		EXEC: begin
			function get_reg [31:0] register;
				input [31:0] num;
				begin
					case (num)
						X0_OPCODE: begin
						end
						X1_OPCODE: begin
						end
						X2_OPCODE: begin
						end
						X3_OPCODE: begin
						end
						X4_OPCODE: begin
						end
						X5_OPCODE: begin
						end
						X6_OPCODE: begin
						end
						X7_OPCODE: begin
						end
						X8_OPCODE: begin
						end
						X9_OPCODE: begin
						end
						X10_OPCODE: begin
						end
						X11_OPCODE: begin
						end
					endcase
				end
			endfunction
			case (current_instr_class)
				TYPE_I: begin
					case (funct3)
						ADDI_FN3: begin
							
						end
						SLTI_FN3: begin
						end
						SLTIU_FN3: begin
						end
						XORI_FN3: begin
						end
						ORI_FN3: begin
						end
						ANDI_FN3: begin
						end
					endcase
				end
				TYPE_B: begin
				end
				TYPE_J: begin
				end
				TYPE_R: begin
				end
				TYPE_S: begin
				end
				TYPE_AUIPC: begin
				end
				TYPE_LUI: begin
				end
			endcase
		end

		IDLE: begin
			if (pc != 0) begin
				current_state <= FETCH;
			end 
		end

		endcase
	end
end

endmodule
