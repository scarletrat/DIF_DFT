----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/30/2025 10:41:29 AM
-- Design Name: 
-- Module Name: DIF_DFT_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity DIF_DFT_tb is
--  Port ( );
end DIF_DFT_tb;

architecture Behavioral of DIF_DFT_tb is
component DIF_DFT
Port ( 
  clk, rst: in std_logic;
  Npoint: in std_logic_vector(7 downto 0); --assuming N = 8
  input_real, input_imj: in  std_logic_vector(15 downto 0);
    output_real,output_imj: out std_logic_vector(15 downto 0)
  );
  end component;
  
  signal clk, rst, start:  std_logic;
  signal Npoint:  std_logic_vector(7 downto 0); --assuming N = 8
  signal input_real, input_imj:   std_logic_vector(15 downto 0);
  signal done:  std_logic;
  signal output_real,output_imj: std_logic_vector(15 downto 0);
begin

dut: DIF_DFT port map( clk=> clk, rst => rst, Npoint => Npoint, input_real => input_real,
input_imj=> input_imj, output_real => output_real,output_imj => output_imj);

process begin
        clk <= '0';
        wait for 4 ns;
        clk <= '1';
        wait for 4 ns;
    end process;
    
process begin
    wait for 4 ns;
    rst <= '1';
    Npoint <= "00001000";
    wait for 4 ns;
    rst <= '0';
    wait for 4 ns;
    input_real <= x"0100";
    input_imj <= x"0000";
    wait for 8 ns;
    input_real <= x"0200";
    input_imj <= x"0000";
    wait for 8 ns;
    input_real <= x"0300";
    input_imj <= x"0000";
    wait for 8 ns;
    input_real <= x"0400";
    input_imj <= x"0000";
    wait for 8 ns;
    input_real <= x"0500";
    input_imj <= x"0000";
    wait for 8 ns;
    input_real <= x"0600";
    input_imj <= x"0000";
    wait for 8 ns;
    input_real <= x"0700";
    input_imj <= x"0000";
    wait for 8 ns;
    input_real <= x"0800";
    input_imj <= x"0000";
    wait;
end process;

end Behavioral;
