----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/13/2019 04:25:53 PM
-- Design Name: 
-- Module Name: ceas - Behavioral
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
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ceas is
    Port ( CLK100MHZ : in STD_LOGIC;
           btnL : in STD_LOGIC;
           btnR : in STD_LOGIC;
           btnC : in STD_LOGIC;
           seg : out STD_LOGIC_VECTOR (0 to 6);
           an : out STD_LOGIC_VECTOR (3 downto 0);
           dp : out STD_LOGIC);
end ceas;

architecture Behavioral of ceas is

component driver7seg is
    Port ( clk : in STD_LOGIC; --100MHz board clock input
           Din : in STD_LOGIC_VECTOR (15 downto 0); --16 bit binary data for 4 displays
           blink : in std_logic_vector (3 downto 0);
           an : out STD_LOGIC_VECTOR (3 downto 0); --anode outputs selecting individual displays 3 to 0
           seg : out STD_LOGIC_VECTOR (0 to 6); -- cathode outputs for selecting LED-s in each display
           dp_in : in STD_LOGIC_VECTOR (3 downto 0); --decimal point input values
           dp_out : out STD_LOGIC; --selected decimal point sent to cathodes
           rst : in STD_LOGIC); --global reset
end component driver7seg;
    
    component DeBounce is
    port(   Clock : in std_logic;
            Reset : in std_logic;
            button_in : in std_logic;
            pulse_out : out std_logic
        );
    end component;
    
    signal blink_ora, blink_min : std_logic;
    signal inc_ore, inc_min, inc_sec : std_logic;
    type states is (afis_timp, set_ore, set_min, set_timp);
    signal current_state : states := afis_timp;
    signal CLK1HZ : std_logic;
    type sec is record
        dig1 : integer range 0 to 9;
        dig2 : integer range 0 to 5;
    end record;
    type min is record
        dig1 : integer range 0 to 9;
        dig2 : integer range 0 to 5;
    end record;
    type ore is record
        dig1 : integer range 0 to 9;
        dig2 : integer range 0 to 2;
    end record;
    type timp is record          
        min : min;
        sec : sec;
        ore : ore;
    end record;
    signal t : timp := ((0,0),(0,0),(0,0)) ;  
    
    signal ore_min : STD_LOGIC_VECTOR (15 downto 0);
    signal sec_sec : STD_LOGIC_VECTOR (15 downto 0);
    signal d : STD_LOGIC_VECTOR (15 downto 0);
    signal btnLd, btnCd, btnRd : std_logic;
begin

deb1 : debounce port map (clock => CLK100MHZ, Reset => '0', button_in => btnL, pulse_out => btnLd);
--deb2 : debounce port map (clock => CLK100MHZ, Reset => '0', button_in => btnC, pulse_out => btnCd);
deb3 : debounce port map (clock => CLK100MHZ, Reset => '0', button_in => btnR, pulse_out => btnRd);


process (CLK100MHZ)
begin
    if rising_edge(CLK100MHZ) then
        case (current_state) is
            when afis_timp => 
                if btnLd = '1' then
                    current_state <= set_ore;
                end if;
            when set_ore => 
                if btnLd = '1' then
                    current_state <= set_min;
                end if;
            when set_min => 
                if btnLd = '1' then
                    current_state <= set_timp;
                end if;
            when set_timp => 
                current_state <= afis_timp;
           end case;
       end if;
   end process;
   
   blink_ora <= '1' when current_state = set_ore else '0';
   blink_min <= '1' when current_state = set_min else '0';
   
process (CLK100MHZ)
    variable i : integer :=0;
begin
    if rising_edge(CLK100MHZ) then
       if i = 100000000 then
           i:=0;
           inc_sec <= '1';
       else 
           i := i+ 1;
           inc_sec <= '0';
       end if;
    end if;
end process;

inc_min <= '1' when current_state = set_min and btnRd = '1' else '0';
inc_ore <= '1' when current_state = set_ore and btnRd = '1' else '0';

process (CLK100MHZ)
begin
    if rising_edge(CLK100MHZ) then
        if inc_sec = '1' then
            if t.sec.dig1 = 9 then
               t.sec.dig1 <= 0;
               if t.sec.dig2 = 5 then
                  t.sec.dig2 <= 0;
                  if t.min.dig1 = 9 then
                     t.min.dig1 <= 0;
                     if t.min.dig2 = 5 then
                        t.min.dig2 <= 0;
                        if t.ore.dig1 = 3 and t.ore.dig2 = 2 then
                            t.ore.dig1 <= 0;
                            t.ore.dig2 <= 0;
                        elsif t.ore.dig1 = 9 then
                            t.ore.dig1 <= 0;
                            t.ore.dig2 <= t.ore.dig2 + 1;
                        else 
                            t.ore.dig1 <= t.ore.dig1 + 1;
                        end if;
                     else
                        t.min.dig2 <= t.min.dig2 + 1;
                     end if;
                  else
                     t.min.dig1 <= t.min.dig1 + 1;   
                  end if;
              else
                  t.sec.dig2 <= t.sec.dig2 + 1; 
              end if;
            else 
                t.sec.dig1 <= t.sec.dig1 + 1;
            end if;
        elsif inc_min = '1' then
            if t.min.dig1 = 9 then
               t.min.dig1 <= 0;
               if t.min.dig2 = 5 then
                  t.min.dig2 <= 0;
               else
                  t.min.dig2 <= t.min.dig2 + 1;
               end if;
            else
               t.min.dig1 <= t.min.dig1 + 1;   
            end if; 
        elsif inc_ore = '1' then
            if t.ore.dig1 = 3 and t.ore.dig2 = 2 then
                t.ore.dig1 <= 0;
                t.ore.dig2 <= 0;
            elsif t.ore.dig1 = 9 then
                t.ore.dig1 <= 0;
                t.ore.dig2 <= t.ore.dig2 + 1;
            else 
                 t.ore.dig1 <= t.ore.dig1 + 1;
            end if;
        end if;
   end if;
end process;

ore_min <= conv_std_logic_vector(t.ore.dig2,4) &
                                 conv_std_logic_vector(t.ore.dig1,4) &
                                 conv_std_logic_vector(t.min.dig2,4) &
                                 conv_std_logic_vector(t.min.dig1,4);
sec_sec <= conv_std_logic_vector(0,4) &
                                 conv_std_logic_vector(0,4) &
                                 conv_std_logic_vector(t.sec.dig2,4) &
                                 conv_std_logic_vector(t.sec.dig1,4);

d <= ore_min when btnC = '0' else sec_sec;

display :  driver7seg port map (
    clk => CLK100MHZ,
    Din => d,
    blink(0) => blink_min,
    blink(1) => blink_min,
    blink(2) => blink_ora,
    blink(3) => blink_ora,
    an => an,
    seg => seg,
    dp_in => (others => '0'),
    dp_out => dp, 
    rst => '0');

end Behavioral;
