import argparse
from dataclasses import dataclass
from enum import Enum

class Ops(Enum):
	I_TYPE = 0b0010011
	S_TYPE = 0b0100011
	R_TYPE = 0b0110011
	J_TYPE = 0b1101111
	B_TYPE = 0b1100011
	LUI    = 0b0110111
	AUIPC  = 0b0010111

class RegOps(Enum):
	x0  = 0b00000
	x1  = 0b00001
	x2  = 0b00010
	x3  = 0b00011
	x4  = 0b00100
	x5  = 0b00101
	x6  = 0b00110
	x7  = 0b00111
	x8  = 0b01000
	x9  = 0b01001
	x10 = 0b01010
	x11 = 0b01011
	x12 = 0b01100
	x13 = 0b01101
	x14 = 0b01110
	x15 = 0b01111
	x16 = 0b10000
	x17 = 0b10001
	x18 = 0b10010
	x19 = 0b10011
	x20 = 0b10100
	x21 = 0b10101
	x22 = 0b10110
	x23 = 0b10111
	x24 = 0b11000
	x25 = 0b11001
	x26 = 0b11010
	x27 = 0b11011
	x28 = 0b11100
	x29 = 0b11101
	x30 = 0b11110
	x31 = 0b11111
	UNDEFINED = -10020

class Func3(Enum):
	ADD_SUB = 0b000   	
	SLL     = 0b001   # SLL, SLLI
	SLT     = 0b010   # SLT, SLTI
	SLTU    = 0b011   # SLTU, SLTIU
	XOR     = 0b100   # XOR, XORI
	SR      = 0b101   # SRL, SRA, SRLI, SRAI
	OR      = 0b110   # OR, ORI
	AND     = 0b111   # AND, ANDI
	UNDEFINED = -1000

class Func7(Enum):
	STD = 0b0000000   
	ALT = 0b0100000

@dataclass
class ITypeInstr: 
	opcode: Ops
	rd: 	RegOps
	func3: 	Func3	
	rs: 	RegOps
	imm: 	int

@dataclass
class JTypeInstr:
	opcode: Ops
	rd:		RegOps
	imm:	int
	imm2:	int

@dataclass
class BTypeInstr:
	opcode: Ops
	imm:	int
	func3:	Func3
	rs1:	RegOps
	rs2:	RegOps
	imm2:	int

@dataclass 
class RTypeInstr:
	opcode: 	Ops
	rd:			RegOps
	func3:		Func3
	rs:			RegOps
	rs2:		RegOps
	func7:		Func7

@dataclass
class UTypeInstr:
	opcode:	Ops
	rd:		RegOps
	imm:	int

@dataclass
class STypeInstr:
	opcode: Ops
	imm:	int
	func:	Func3
	rs1:	RegOps
	rs2:	RegOps
	imm2:	int

def parse_file(file_path: str) -> list[str]:
	res = []
	with open(file_path, "r", encoding="utf-8") as f:
		for line in f: res.append(line)
	
	return res

def get_f3(name: str) -> Func3:
	cmp = lambda instrs: name in instrs

	if cmp(("add", "sub", "addi")): return Func3.ADD_SUB
	if cmp(("sll", "slli")): return Func3.SLL
	if cmp(("slt", "slti")): return Func3.SLT
	if cmp(("sltu", "sltiu")): 	return Func3.SLTU
	if cmp(("xor", "xori")): return Func3.XOR
	if cmp(("srl", "sra", "srli", "srai")): return Func3.SR
	if cmp(("or", "ori")): return Func3.OR
	if cmp(("and", "andi")): return Func3.AND

	return Func3.UNDEFINED

def get_reg(name: str) -> RegOps:
    match name:
        case "x0":  return RegOps.x0
        case "x1":  return RegOps.x1
        case "x2":  return RegOps.x2
        case "x3":  return RegOps.x3
        case "x4":  return RegOps.x4
        case "x5":  return RegOps.x5
        case "x6":  return RegOps.x6
        case "x7":  return RegOps.x7
        case "x8":  return RegOps.x8
        case "x9":  return RegOps.x9
        case "x10": return RegOps.x10
        case "x11": return RegOps.x11
        case "x12": return RegOps.x12
        case "x13": return RegOps.x13
        case "x14": return RegOps.x14
        case "x15": return RegOps.x15
        case "x16": return RegOps.x16
        case "x17": return RegOps.x17
        case "x18": return RegOps.x18
        case "x19": return RegOps.x19
        case "x20": return RegOps.x20
        case "x21": return RegOps.x21
        case "x22": return RegOps.x22
        case "x23": return RegOps.x23
        case "x24": return RegOps.x24
        case "x25": return RegOps.x25
        case "x26": return RegOps.x26
        case "x27": return RegOps.x27
        case "x28": return RegOps.x28
        case "x29": return RegOps.x29
        case "x30": return RegOps.x30
        case "x31": return RegOps.x31
        case _: raise ValueError(f"Undefined register {name}")

def get_f7(name: str) -> Func7: return Func7.ALT if name == ("sub", "sra") else Func7.STD
def rplc_instr(instr: str) -> list[str]: return instr.replace(",", " ").split()

def parse_i_instr(s: str) -> ITypeInstr:
	instr = rplc_instr(s)
	return ITypeInstr(
		opcode=Ops.I_TYPE,
		rd=get_reg(instr[1]),
		func3=get_f3(instr[0]),
		rs=get_reg(instr[2]),
		imm=int(instr[3])
	)

def parse_j_instr(s: str) -> JTypeInstr:
    instr = rplc_instr(s)
    return JTypeInstr(
        opcode=Ops.J_TYPE,
        rd=get_reg(instr[1]),
        imm=int(instr[2])   
	)

def parse_r_instr(s: str) -> RTypeInstr:
    instr = rplc_instr(s)
    return RTypeInstr(
        opcode=Ops.R_TYPE,
        rd=get_reg(instr[1]),
        func3=get_f3(instr[0]),
        func7=get_f7(instr[0]),
        rs1=get_reg(instr[2]),
        rs2=get_reg(instr[3])
    )

def parse_u_instr(s: str) -> UTypeInstr:
    instr = rplc_instr(s)
    return UTypeInstr(
        opcode=Ops.LUI if instr[0] == "lui" else Ops.AUIPC,
        rd=get_reg(instr[1]),
        imm=int(instr[2])
    )

def parse_s_instr(s: str) -> STypeInstr:
    instr = rplc_instr(s)
    return STypeInstr(
        opcode=Ops.S_TYPE,
        func3=get_f3(instr[0]),
        rs1=get_reg(instr[1]),
        rs2=get_reg(instr[2]),
        imm=int(instr[3])
    )

def encode_i_instr(instr: ITypeInstr) -> int:
	return ((instr.imm & 0xFFF) << 20) | (instr.rs.value << 15) | (instr.func3.value << 12) | (instr.rd.value << 7) | instr.opcode.value

def encode_j_instr(instr: JTypeInstr) -> int:
	return (0b0 << 30) | ((instr.imm2 & 0x3FF) << 21) | (0b0 << 20) | ((instr.imm & 0xFF) << 12) | (instr.rd.value << 7) | instr.opcode.value

def encode_r_instr(instr: RTypeInstr) -> int:
	return (
		(instr.func7.value << 25) | (instr.rs2.value << 20) |
		(instr.rs.value << 15) | (instr.func3.value << 12) |
		(instr.rd.value << 7) | instr.opcode.value
	)

def encode_u_instr(instr: UTypeInstr) -> int:
	return (
		((instr.imm & 0xFFFFF) << 12) | 
		(instr.rd.value << 7) | instr.opcode.value
	)

def encode_s_instr(instr: STypeInstr) -> int:
	return (
		((instr.imm2 & 0x7F) << 25) | (instr.rs2.value << 20) |
		(instr.rs.value << 15) | (instr.func3.value << 12) | 
		(instr.imm << 7) | instr.opcode.value
	)

def is_i_instr(name: str) -> bool:
	instrs = (
		"addi", "slti", "sltiu", "xori",
		"ori", "andi", "slli", "srli", "srai",
		"jalr", "lb", "lh", "lw", "lbu", "lhu"
	)
	return True if name in instrs else False

def is_u_instr(name: str) -> bool: return True if name in ("lui", "auipc") else False
def is_s_instr(name: str) -> bool: return True if name in ("sb", "sh", "sw") else False
def is_j_instr(name: str) -> bool: return True if name == "jal" else False

def is_r_instr(name: str) -> bool:
	return True if name in ("add", "sub", "sll", "slt", "sltu", "xor", "srl", "sra", "or", "and") else False

def parse_instrs(instrs: list[str]) -> list[int]:
	res = []
	for instr in instrs:
		mod_instr = instr.rstrip().lower()
		name = mod_instr.split(' ')[0]
		if is_i_instr(name):
			res.append(encode_i_instr(parse_i_instr(mod_instr)))
			continue

		if is_u_instr(name):
			res.append(encode_u_instr(parse_u_instr(mod_instr)))
			continue

		if is_s_instr(name): 
			res.append(encode_s_instr(parse_s_instr(mod_instr)))
			continue

		if is_j_instr(name):
			res.append(encode_j_instr(parse_j_instr(mod_instr)))
			continue

		if is_r_instr(name):
			res.append(encode_r_instr(parse_r_instr(mod_instr)))
			continue

	return res

def main() -> None:
	parser = argparse.ArgumentParser(description="rv32i")
	parser.add_argument("file_path", type=str, help="Your file")
	parser.add_argument("-o", type=str, help="Your output file name")
	parser.add_argument("-b", type=bool, help="Output in binary format")

	args = parser.parse_args()
	data = parse_file(args.file_path)
	
	instrs = parse_instrs(data)
	instrs_str = " ".join(map(hex, instrs)) if not args.b else " ".join(map(bin, instrs))
	if args.o is not None:
		with open(args.o, "a") as f:
			f.write(" ".join(instrs_str) + "\n")
	else:
		print(instrs_str)

if __name__ == "__main__":
	try:
		main()
	except KeyboardInterrupt:
		print("\nExited.")
