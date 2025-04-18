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
    signal clk_div        : std_logic;
    signal floor_0        : std_logic_vector(3 downto 0);  -- from FSM
    signal hex_disp       : std_logic_vector(3 downto 0);  -- for 7seg decoder
    signal disp_select    : std_logic_vector(3 downto 0);  -- from TDM
    signal reset_clk      : std_logic;
    signal reset_fsm      : std_logic;
    signal reset_master   : std_logic;
    signal tdm_data       : std_logic_vector(3 downto 0);
  
	-- component declarations
    component sevenseg_decoder is
        port (
            i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
            o_seg_n : out STD_LOGIC_VECTOR (6 downto 0)
        );
    end component sevenseg_decoder;
    
    component elevator_controller_fsm is
		Port (
            i_clk        : in  STD_LOGIC;
            i_reset      : in  STD_LOGIC;
            is_stopped   : in  STD_LOGIC;
            go_up_down   : in  STD_LOGIC;
            o_floor : out STD_LOGIC_VECTOR (3 downto 0)		   
		 );
	end component elevator_controller_fsm;
	
	component TDM4 is
		generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
        Port ( i_clk		: in  STD_LOGIC;
           i_reset		: in  STD_LOGIC; -- asynchronous
           i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
	   );
    end component TDM4;
     
	component clock_divider is
        generic ( constant k_DIV : natural := 2	); -- How many clk cycles until slow clock toggles
                                                   -- Effectively, you divide the clk double this 
                                                   -- number (e.g., k_DIV := 2 --> clock divider of 4)
        port ( 	i_clk    : in std_logic;
                i_reset  : in std_logic;		   -- asynchronous
                o_clk    : out std_logic		   -- divided (slow) clock
        );
    end component clock_divider;
	
begin
	-- PORT MAPS ----------------------------------------
    -- Reset logic (active-high)
    reset_master <= btnU;
    reset_clk    <= btnL;
    reset_fsm    <= btnR;
    
    -- LED 15 shows the FSM clock
    led(15) <= clk_div;
    led(14 downto 0) <= (others => '0'); -- unused
    
    -- Clock Divider instance (0.5s pulse from 100 MHz)
    clk_div_inst : clock_divider
        generic map (k_DIV => 25000000)
        port map (
            i_clk    => clk,
            i_reset  => reset_clk,
            o_clk    => clk_div
        );
	
    -- Elevator FSM instance (only single elevator for now)
    elevator0 : elevator_controller_fsm
        port map (
            i_clk       => clk_div,
            i_reset     => reset_fsm,
            is_stopped  => sw(14),        -- tie to sw14 as stop
            go_up_down  => sw(15),        -- tie to sw15 as up/down
            o_floor     => floor_0
        );

    -- Time-Division Multiplexing: 4 displays (D3 to D0)
    mux_disp : TDM4
        generic map (k_WIDTH => 4)
        port map (
            i_clk  => clk,
            i_reset => reset_master,
            i_D3 => x"F",        -- display 3 = F
            i_D2 => floor_0,     -- display 2 = elevator floor
            i_D1 => x"F",        -- display 1 = F
            i_D0 => x"0",        -- display 0 = 0 (or can be another floor input later)
            o_data => tdm_data,
            o_sel => disp_select
        );

    -- 7-segment decoding
    sseg : sevenseg_decoder
        port map (
            i_Hex => tdm_data,
            o_seg_n => seg
        );

    -- Anode control
    an <= not disp_select;
	
end top_basys3_arch;
