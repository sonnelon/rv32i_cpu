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
			case (current_instr_class)
				TYPE_I: begin
					case (funct3)
						ADDI_FN3: begin
							regs[rd] <= regs[rs] + i_type_imm;
							current_state <= IDLE;
						end
						SLTI_FN3: begin
							if ($signed(regs[rs1]) < $signed(i_type_imm)) begin
								regs[rd] <= 1;
								current_state <= IDLE;
							end else begin
								regs[rd] <= 0;
								current_state <= IDLE;
							end
						end
						SLTIU_FN3: begin
							if ($unsigned(regs[rs1]) < $unsigned(regs[rd])) begin
								regs[rd] <= 1;
								current_state <= IDLE;
							end else begin
								regs[rd] <= 0;
								current_state <= IDLE;
							end
						end
						XORI_FN3: begin
							regs[rd] <= regs[rs1] ^ i_type_imm;
							current_state <= IDLE;
						end
						ORI_FN3: begin
							regs[rd] <= regs[rs1] | i_type_imm;
							current_state <= IDLE;
						end
						ANDI_FN3: begin
							regs[rd] <= regs[rs1] & i_type_imm;
							current_state <= IDLE;
						end
					endcase
				end
				TYPE_B: begin
				end
				TYPE_J: begin
				end
				TYPE_R: begin
					if (funct3 == ADD_FN3 && funct7 == ADD_FN7) begin
						regs[rd] <= regs[rs1] + regs[rs2];
						current_state <= IDLE;
					end else if (funct3 == SUB_FN3 && funct7 == SUB_FN7) begin
						regs[rd] <= regs[rs1] - regs[rs2];
						current_state <= IDLE;
					end else if (funct3 == SLL_FN3 && funct7 == SLL_FN7) begin
						regs[rd] <= regs[rs1] << regs[rs2];
						current_state <= IDLE;
					end else if (funct3 == SLT_FN3 && funct7 == SLT_FN7) begin
						if ($signed(regs[rs1]) < $signed(regs[rs2])) begin
							regs[rd] <= 1;
							current_state <= IDLE;
						end else begin
							regs[rd] <= 0;
							current_state <= IDLE;
						end
					end else if (funct3 == SLTU_FN3 && funct7 == SLTU_FN7) begin
						if ($unsigned(regs[rs1]) < $unsigned(regs[rs2])) begin
							regs[rd] <= 1;
							current_state <= IDLE;
						end else begin
							regs[rd] <= 0;
							current_state <= IDLE;
						end
					end else if (funct3 == XOR_FN3 && funct7 == XOR_FN7) begin
						regs[rd] <= regs[rs1] ^ regs[rs2];
						current_state <= IDLE;
					end else if (funct3 == SRL_FN3 && funct7 == SRL_FN7) begin
						regs[rd] <= regs[rs1] >> regs[rs2];
						current_state <= IDLE;
					end else if (funct3 == SRA_FN3 && funct7 == SRA_FN7) begin
						regs[rd] <= regs[rs1] >> regs[rs2];
						current_state <= IDLE;
					end else if (funct3 == OR_FN3 && funct7 == OR_FN7) begin
						regs[rd] <= regs[rs1] | regs[rs2];
						current_state <= IDLE;
					end else if (funct3 == AND_FN3 && funct7 == AND_FN7) begin
						regs[rd] <= regs[rs1] & regs[rs2];
						current_state <= IDLE;
					end
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
