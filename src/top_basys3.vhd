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

    -- Signals
    signal clk_div      : std_logic;
    signal floor_0      : std_logic_vector(3 downto 0);
    signal floor_1      : std_logic_vector(3 downto 0);
    signal tdm_data     : std_logic_vector(3 downto 0);
    signal tdm_sel      : std_logic_vector(3 downto 0);
    signal reset_clk    : std_logic;
    signal reset_fsm    : std_logic;
    signal reset_master : std_logic;
    signal seg_temp     : std_logic_vector(6 downto 0);

    -- Component declarations
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

    component TDM4 is
        generic ( constant k_WIDTH : natural := 4 );
        port (
            i_clk   : in std_logic;
            i_reset : in std_logic;
            i_D3    : in std_logic_vector(k_WIDTH - 1 downto 0);
            i_D2    : in std_logic_vector(k_WIDTH - 1 downto 0);
            i_D1    : in std_logic_vector(k_WIDTH - 1 downto 0);
            i_D0    : in std_logic_vector(k_WIDTH - 1 downto 0);
            o_data  : out std_logic_vector(k_WIDTH - 1 downto 0);
            o_sel   : out std_logic_vector(3 downto 0)
        );
    end component;

begin

    -- Reset assignments
    reset_master <= btnU;
    reset_clk    <= btnL;
    reset_fsm    <= btnR;

    -- Clock divider
    clk_div_inst : clock_divider
        generic map (k_DIV => 25000000)
        port map (
            i_clk   => clk,
            i_reset => reset_clk,
            o_clk   => clk_div
        );

    -- Elevator FSMs
    elevator0 : elevator_controller_fsm
        port map (
            i_clk       => clk_div,
            i_reset     => reset_fsm,
            is_stopped  => sw(0),
            go_up_down  => sw(1),
            o_floor     => floor_0
        );

    elevator1 : elevator_controller_fsm
        port map (
            i_clk       => clk_div,
            i_reset     => reset_fsm,
            is_stopped  => sw(14),
            go_up_down  => sw(15),
            o_floor     => floor_1
        );

    -- TDM4 instance: only digits 0 and 2 used
    mux_disp : TDM4
        generic map (k_WIDTH => 4)
        port map (
            i_clk   => clk,              -- 100MHz clock for display refresh
            i_reset => reset_master,
            i_D3    => "0000",           -- digit 3: off
            i_D2    => floor_1,          -- digit 2: Elevator 1
            i_D1    => "0000",           -- digit 1: off
            i_D0    => floor_0,          -- digit 0: Elevator 0
            o_data  => tdm_data,
            o_sel   => tdm_sel
        );

    -- 7-segment decoder
    sseg : sevenseg_decoder
        port map (
            i_Hex   => tdm_data,
            o_seg_n => seg_temp
        );

    -- Synchronized display update (prevents overlap/glitching)
    process(clk)
    begin
        if rising_edge(clk) then
            case tdm_sel is
                when "1110" =>  -- digit 0 (Elevator 0)
                    an  <= "1110";
                    seg <= seg_temp;
                when "1011" =>  -- digit 2 (Elevator 1)
                    an  <= "1011";
                    seg <= seg_temp;
                when others =>
                    an  <= "1111";       -- all digits off
                    seg <= "1111111";    -- blank
            end case;
        end if;
    end process;

    -- Debug LEDs
    led(15)         <= clk_div;
    led(14 downto 8) <= (others => '0');
    led(7 downto 4) <= floor_1;  -- show Elevator 1 floor
    led(3 downto 0) <= floor_0;  -- show Elevator 0 floor

end top_basys3_arch;