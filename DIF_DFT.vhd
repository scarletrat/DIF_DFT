library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity DIF_DFT is
  Port ( 
  clk, rst: in std_logic;
  Npoint: in std_logic_vector(7 downto 0); --assuming N = 8
  input_real, input_imj: in  std_logic_vector(15 downto 0);
  output_real,output_imj: out std_logic_vector(15 downto 0)
    );
end DIF__DFT;

architecture Behavioral of DIF_DFT is
component butterfly port(
  clk, start : in std_logic;
  a0,a1: in std_logic_vector(15 downto 0); --A_real, A_imj
  b0,b1: in std_logic_vector(15 downto 0); --B_real, B_imj
  wre,wim: in std_logic_vector(15 downto 0); --Twiddle real, imj
  control: in std_logic; -- 0 = subtract*twiddle, 1 = add
  done: out std_logic;
  output_real,output_imj: out std_logic_vector(15 downto 0)
);
end component;

signal a0,a1,b0,b1,wre,wim: std_logic_vector(15 downto 0);
signal control: std_logic;

type statemachine is (store, temp1, top_comp, wait1, store_comp1, 
btm_comp, wait2, store_comp2, end_comp, finish_dft, output_dft, end_state,
wait1long, wait2long);
signal state:statemachine;

type memory is array(0 to 40) of std_logic_vector(31 downto 0);
signal mem: memory:= (others=>(others=>'0'));

type twiddle_memory is array (0 to 3) of std_logic_vector(15 downto 0);
signal twiddle_real: twiddle_memory:=(x"0100",x"00B5", x"0000", x"FF4B");
signal twiddle_imj: twiddle_memory:=(x"0000",x"FF4B", x"FF00", x"FF4B");


signal Ntemp,Ntemp2: integer range 0 to 255 := 0;
signal N: integer range 0 to 128:= 0;
signal count: integer range 0 to 255:= 0;
signal index_start: integer range 0 to 255 := 0;
signal number_of_DFT, number_of_DFT_temp: integer range 0 to 255 := 1;
signal this_stage_index: integer range 1 to 16:=1;
signal twiddle_index: integer range 0 to 128:=0;


signal output_imj_temp, output_real_temp: std_logic_vector(15 downto 0);
signal start, done: std_logic;
begin

u1: butterfly port map(clk => clk, a0 => a0, a1 => a1, b0 => b0, b1 => b1, control => control,
wre=>wre,wim=>wim,output_imj=>output_imj_temp, output_real => output_real_temp, start => start, done => done);

process (clk) begin
    if rising_edge(clk) then
        if rst = '1' then 
            state <= store;
            Ntemp <= 0;
            mem <= (others=>(others =>'0'));
            index_start <= 0;
            Ntemp <= 0;
            Ntemp2 <= 0;
            count <= 0;
            start <= '0';
            number_of_DFT <= 1;
            number_of_DFT_temp <= 1;
            this_stage_index <= 1;
            twiddle_index <= 0;
            N <= to_integer(unsigned(Npoint));
        else
            case state is
                when store =>
                --Store the x(n) values
                    if Ntemp < (N) then
                        Ntemp <= Ntemp + 1;
                        mem(Ntemp)<= input_real & input_imj ;
                        state <= store;
                    else
                        state <= temp1;
                        
                    end if;
                
                when temp1 =>
                --Some sort of computation stage after storing
                if Ntemp /= 1 then
                    Ntemp <= Ntemp/2;
                    state <= top_comp;
                else
                    state <= finish_dft;
                end if;
                when top_comp=>
                if Ntemp2 < Ntemp then
                    a0<= mem(index_start + Ntemp2)(31 downto 16); --real
                    a1<= mem(index_start + Ntemp2)(15 downto 0); --imj
                    b0<= mem(index_start + Ntemp2 + Ntemp)(31 downto 16);
                    b1<= mem(index_start + Ntemp2 + Ntemp)(15 downto 0);
                    control <= '1';
                    Ntemp2 <= Ntemp2 + 1;
                    start <= '1';
                    state <= wait1;
                else
                    state <= btm_comp;
                    Ntemp2 <= 0;
                end if;
                when wait1 =>
                --stage for calculation
                start <= '0';
                state <= wait1long;
                when wait1long =>
                if done = '1' then
                    state <= store_comp1;
                end if;
                when store_comp1 =>
                    mem(N+count)<= output_real_temp  & output_imj_temp;
                    count <= count + 1;
                    state <= top_comp;
                when btm_comp =>
                if Ntemp2 < Ntemp then
                    a0<= mem(index_start + Ntemp2)(31 downto 16); --real
                    a1<= mem(index_start + Ntemp2)(15 downto 0); --imj
                    b0<= mem(index_start + Ntemp2 + Ntemp)(31 downto 16);
                    b1<= mem(index_start + Ntemp2 + Ntemp)(15 downto 0);
                    --Twiddle factor is W_Ntemp ^Ntemp2, not sure how to include it
                    wre <= twiddle_real(twiddle_index);
                    wim <= twiddle_imj(twiddle_index);
                    control <= '0'; 
                    Ntemp2 <= Ntemp2 + 1;
                    start <= '1';
                    state <= wait2;
                else
                    state <= end_comp;
                    Ntemp2 <= 0;
                end if;
                when wait2 =>
                    start <= '0';
                    state <= wait2long;
                when wait2long =>
                    if done = '1' then
                        state<=store_comp2;
                        twiddle_index <= this_stage_index + twiddle_index;
                    end if;
                when store_comp2 =>
                    mem(N+count)<= output_real_temp  & output_imj_temp;
                    count <= count + 1;
                    state <= btm_comp;
                when end_comp =>
                    if number_of_DFT = number_of_DFT_temp  then
                        number_of_DFT <= number_of_DFT *2;
                        index_start <= Ntemp*2 + index_start;
                        number_of_DFT_temp <= 1; --reset it back
                        state <= temp1;
                        this_stage_index <= this_stage_index +1;
                    else
                        number_of_DFT_temp <= number_of_DFT_temp + 1;
                        index_start <= index_start + 2*Ntemp;
                        state <=top_comp;
                    end if;
                    twiddle_index <= 0;
                when finish_dft =>
                count <= count - N;
                state <= output_dft;
                when output_dft =>
                if (Ntemp2) < (N) then
                        count <= count + 1;
                        Ntemp2 <= Ntemp2 + 1;
                        output_real <= mem(N+count)(31  downto 16);
                        output_imj <= mem(N+count)(15  downto 0);
                    else
                        Ntemp2 <= 0;
                        state <= end_state;                    
                    end if;
                when end_state =>
                
            end case;
        end if;
    
    end if;

end process;

end Behavioral;
