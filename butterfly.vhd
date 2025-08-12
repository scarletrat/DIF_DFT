library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity butterfly is
  Port ( 
  clk,start : in std_logic;
  a0,a1: in std_logic_vector(15 downto 0); --A_real, A_imj
  b0,b1: in std_logic_vector(15 downto 0); --B_real, B_imj
  wre,wim: in std_logic_vector(15 downto 0); --Twiddle real, imj
  control: in std_logic; -- 0 = subtract*twiddle, 1 = add
  done: out std_logic;
  output_real,output_imj: out std_logic_vector(15 downto 0)
  );
end butterfly;

architecture Behavioral of butterfly is
    signal a0_s, a1_s, b0_s, b1_s : signed(15 downto 0);
    signal wre_s, wim_s : signed(15 downto 0);

    signal sum_re, sum_im : signed(15 downto 0);
    signal diff_re, diff_im : signed(15 downto 0);
    
    signal mult1, mult2, mult3, mult4: signed(31 downto 0);
    signal temp1, temp2: std_logic_vector(31 downto 0);
    
    type statemachine is (start_state, calc1, calc2, calc3, send, finish);
    signal state: statemachine:= start_state;

begin


process(clk) begin
    if rising_edge(clk) then
        
        case state is
        
        when start_state =>
            if start = '1' then
                a0_s <= signed(a0); a1_s <= signed(a1);
                b0_s <= signed(b0); b1_s <= signed(b1);
                wre_s <= signed(wre); wim_s <= signed(wim);
                
                state <= calc1;
                done <= '0';
            end if;
       when calc1 =>    
                if control = '0' then
            -- Twiddle path: (A - B) * W
                    diff_re <= (a0_s - b0_s);
                    diff_im <= (a1_s - b1_s);
                    state <= calc2;    
                else
                    output_real <= std_logic_vector(a0_s + b0_s);
                    output_imj <=  std_logic_vector(a1_s + b1_s );
                    state <= finish;
                end if;
            
        when calc2 =>
            -- real = diff_re * wre - diff_im * wim
                mult1 <= ((diff_re * wre_s));
                mult2 <= ((diff_im * wim_s));

            -- imag = diff_re * wim + diff_im * wre
                mult3 <= ((diff_re * wim_s));
                mult4 <= ((diff_im * wre_s));
                state <= calc3;
        when calc3 => 
            temp1 <= std_logic_vector((mult1 - mult2));
            temp2 <= std_logic_vector(mult3 + mult4);
            state <= send;
        when send =>
            output_real <= temp1(23 downto 8);  
            output_imj  <= temp2(23 downto 8);  
            state <= finish;
        when finish =>  
            done <= '1';
            state <= start_state;
        when others =>
            state <= start_state;
        end case;        
        
    end if;
end process;

end Behavioral;
