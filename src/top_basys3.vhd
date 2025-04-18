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
    signal clk_div      : std_logic;
    signal floor_0      : std_logic_vector(3 downto 0);
    signal floor_1      : std_logic_vector(3 downto 0);
    signal reset_clk    : std_logic;
    signal reset_fsm    : std_logic;
    signal reset_master : std_logic;

    -- Display control
    signal seg_val0     : std_logic_vector(6 downto 0);
    signal seg_val2     : std_logic_vector(6 downto 0);

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
        generic ( constant k_DIV : natural := 25000000 );
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

    -- Clock divider instance
    clk_div_inst : clock_divider
        generic map (k_DIV => 25000000)
        port map (
            i_clk   => clk,
            i_reset => reset_clk,
            o_clk   => clk_div
        );

    -- Elevator 0 FSM
    elevator0 : elevator_controller_fsm
        port map (
            i_clk       => clk_div,
            i_reset     => reset_fsm,
            is_stopped  => sw(14),
            go_up_down  => sw(15),
            o_floor     => floor_0
        );

    -- Elevator 1 FSM
    elevator1 : elevator_controller_fsm
        port map (
            i_clk       => clk_div,
            i_reset     => reset_fsm,
            is_stopped  => sw(14),
            go_up_down  => sw(15),
            o_floor     => floor_1
        );

    -- Decode floor_0 to seg_val0 (digit 0)
    sseg0 : sevenseg_decoder
        port map (
            i_Hex   => floor_0,
            o_seg_n => seg_val0
        );

    -- Decode floor_1 to seg_val2 (digit 2)
    sseg2 : sevenseg_decoder
        port map (
            i_Hex   => floor_1,
            o_seg_n => seg_val2
        );

    -- Output logic
    -- Only one display active at a time (hardcoded control)
    process(clk)
    variable count : integer range 0 to 1 := 0;
    begin
        if rising_edge(clk) then
            count := count + 1;
            if count = 2 then
                count := 0;
            end if;

            case count is
                when 0 =>
                    an  <= "1110";  -- Enable digit 0
                    seg <= seg_val0;
                when 1 =>
                    an  <= "1011";  -- Enable digit 2
                    seg <= seg_val2;
                when others =>
                    an  <= "1111";
                    seg <= "1111111";
            end case;
        end if;
    end process;

    -- Debug LEDs
    led(15) <= clk_div;
    led(14 downto 0) <= (others => '0');

end top_basys3_arch;
