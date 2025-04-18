library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


-- Lab 4
entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(15 downto 0);
        btnU    :   in std_logic; -- master_reset
        btnL    :   in std_logic; -- clk_reset
        btnR    :   in std_logic; -- fsm_reset
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is

    -- signal declarations
    signal clk_div     : std_logic;
    signal floor_0     : std_logic_vector(3 downto 0);  -- from FSM
    signal reset_clk   : std_logic;
    signal reset_fsm   : std_logic;
    signal reset_master: std_logic;

    -- component declarations
    component sevenseg_decoder is
        port (
            i_Hex   : in std_logic_vector(3 downto 0);
            o_seg_n : out std_logic_vector(6 downto 0)
        );
    end component;

    component elevator_controller_fsm is
        port (
            i_clk       : in std_logic;
            i_reset     : in std_logic;
            is_stopped  : in std_logic;
            go_up_down  : in std_logic;
            o_floor     : out std_logic_vector(3 downto 0)
        );
    end component;

    component clock_divider is
        generic ( constant k_DIV : natural := 25000000 ); -- 0.5s at 100MHz
        port (
            i_clk   : in std_logic;
            i_reset : in std_logic;
            o_clk   : out std_logic
        );
    end component;

begin

    -- Reset assignments
    reset_master <= btnU;
    reset_clk    <= btnL;
    reset_fsm    <= btnR;

    -- Clock divider instance (0.5s slow clock)
    clk_div_inst : clock_divider
        generic map (k_DIV => 25000000)
        port map (
            i_clk   => clk,
            i_reset => reset_clk,
            o_clk   => clk_div
        );

    -- FSM instance (controls elevator 0)
    elevator0 : elevator_controller_fsm
        port map (
            i_clk       => clk_div,
            i_reset     => reset_fsm,
            is_stopped  => sw(14),
            go_up_down  => sw(15),
            o_floor     => floor_0
        );

    -- 7-segment decoding (only rightmost digit used)
    sseg : sevenseg_decoder
        port map (
            i_Hex   => floor_0,
            o_seg_n => seg
        );

    -- Enable only rightmost digit (digit 0 is active-low)
    an <= "1110";

    -- Debug LEDs
    led(15) <= clk_div;
    led(14 downto 0) <= (others => '0');

end top_basys3_arch;
