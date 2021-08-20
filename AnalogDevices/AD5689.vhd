----------------------------------------------------------------------------------
-- Company: Cartoons and Chaos
-- Engineer: Joseph Pierce Vincent
-- Email: Josephpiercevincent@gmail.com
-- 
-- Create Date: 08/20/2021 10:20:14 AM
-- Design Name: 
-- Module Name: AD5689 - Behavioral
-- Project Name: AD5689 Sim
-- Target Devices: N/A
-- Tool Versions: Vivado 2019.1
-- Description: This is a VHDL simulation module of the Analog Devices AD5689 nanoDac device.
--              This module aims to assist in simulating larger scale projects which will utilize
--              this DAC. Accuracy is not guaranteed and as always a 'smart' reference would be to 
--              refer to the Analog Devices data sheet at :
--              https://www.analog.com/media/en/technical-documentation/data-sheets/AD5689_5687.pdf
--              This will ensure that any driver code developed will align with the theoretical function
--              of the circuit as described in the datasheet.
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments: Just a basic model of the DAC for now which should accept 
--                      SPI writes and output on the proper channel depending on the incoming
--                      DAC code.
-- 
----------------------------------------------------------------------------------


library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity AD5689 is
  Port ( 
    POWER_ON : in STD_LOGIC;
  
    SCLK : in STD_LOGIC;
    SYNCn : in STD_LOGIC;
    SDIN : in STD_LOGIC;
    LDACn : in STD_LOGIC;
    RSTn : in STD_LOGIC;
    GAIN : in STD_LOGIC;
    
    VOUTA : out STD_LOGIC_VECTOR(16 downto 0);
    VOUTB : out STD_LOGIC_VECTOR(16 downto 0)
  
  );
end AD5689;

architecture Behavioral of AD5689 is

CONSTANT dacA_addr : STD_LOGIC_VECTOR(3 downto 0) := "0001";
CONSTANT dacB_addr : STD_LOGIC_VECTOR(3 downto 0) := "1000";
CONSTANT dacAB_addr : STD_LOGIC_VECTOR(3 downto 0) := "1001";


--Interface Logic Registers
signal input_shift_Reg : STD_LOGIC_VECTOR(24 downto 0);
signal dacReg_ce : STD_LOGIC_VECTOR(1 downto 0);


--Post Intf Logic Registers
signal inputA_reg : STD_LOGIC_VECTOR(15 downto 0) := x"00000";
signal dacA_reg : STD_LOGIC_VECTOR(15 downto 0) := x"0000";
signal inputB_reg : STD_LOGIC_VECTOR(15 downto 0) := x"00000";
signal dacB_reg : STD_LOGIC_VECTOR(15 downto 0) := x"0000";

signal intf_logic_cntr : integer range 0 to 25;

begin

intf_logic : process(SCLK, LDACn, RSTn, SDIN)
BEGIN
    if RSTn = '0' then
        dacReg_ce <= "11";
        input_shift_Reg <= "00000000" & x"8000";
    elsif SYNCn = '0' and LDACn = '1' then
        intf_logic_cntr <= 0;
        
        if input_shift_Reg(24 downto 21) = dacA_addr then
            dacReg_ce <= "01";
        elsif input_shift_reg(24 downto 21) = dacB_addr then
            dacReg_ce <= "10";
        elsif input_shift_reg(24 downto 21) = dacAB_addr then
            dacReg_ce <= "11";        
        end if;
        
    elsif falling_edge(SCLK) then
        dacReg_ce <= "00";

        if intf_logic_cntr < 25 then    -- SHIFT IN AN INCREMENT COUNTER
            input_shift_Reg <= input_shift_Reg(23 downto 0) & SDIN;
            intf_logic_cntr <= intf_logic_cntr + 1;
       
        else    -- DUMP REGISTER BECAUSE WE OVERSHOT WRITES
            input_shift_Reg <= (OTHERS=>'0');
            intf_logic_cntr <= 0;
        end if;
    end if;
    
END PROCESS;

inputA_reg <=  input_shift_Reg(15 downto 0) when dacReg_ce(0) = '1';
inputB_reg <= input_shift_Reg(15 downto 0) when dacReg_ce(1) = '1';

dacA_reg <= inputA_reg when LDACn = '0' or RSTn = '0';
dacB_reg <= inputB_reg when LDACn = '0' or RSTn = '0';

VOUTA <= dacA_reg(15 downto 0) & "0" when GAIN = '1' else "0" & dacA_reg(15);

VOUTB <= dacB_reg(15 downto 0) & "0" when GAIN = '1' else "0" & dacB_reg(15);


end Behavioral;
