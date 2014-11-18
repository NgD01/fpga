library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library unisim;
use unisim.vcomponents.all;
use work.defines.all;
use work.hdmi_definitions.all;

entity System is
  Port ( -- Stuff
         clk : in std_logic;
         clk_sys_out : out std_logic;
--         reset : in std_logic;

         -- SRAM
--         sram_bus_data_1_inout : inout sram_bus_data_t;
--         sram_bus_control_1_out : out sram_bus_control_t;
--
--         sram_bus_1_lb_out_n   : out std_logic   := '0';
--         sram_bus_1_ub_out_n   : out std_logic   := '0';
--         sram_1_enable_n     : out std_logic     := '0';
--
--         sram_bus_data_2_inout : inout sram_bus_data_t;
--         sram_bus_control_2_out : out sram_bus_control_t;
--
--         sram_bus_2_lb_out_n : out std_logic := '0';
--         sram_bus_2_ub_out_n : out std_logic := '0';
--         sram_2_enable_n     : out std_logic := '0';

         -- HDMI
         hdmi_connector_out : out hdmi_connector_t;

         -- MC EBI
         ebi_data_inout : inout ebi_data_t;
         ebi_control_in : in ebi_control_t;

         -- MC Special kernel complete flag
         mc_kernel_complete_out : out std_logic;
         mc_frame_buffer_select_in : in std_logic;
        
          debug_signal0 : out std_logic := '0';
          debug_signal1 : out std_logic := '0';
          debug_signal2 : out std_logic := '0';

         -- MC SPI
--         mc_spi_bus : inout spi_bus_t;

         -- Generic IO
         led_1_out : out STD_LOGIC;
         led_2_out : out STD_LOGIC);
end System;

architecture Behavioral of System is
  
  signal sram_bus_data_1_inout : sram_bus_data_t;
  signal sram_bus_control_1_out : sram_bus_control_t;

  signal sram_bus_1_lb_out_n   : std_logic   := '0';
  signal sram_bus_1_ub_out_n   : std_logic   := '0';
  signal sram_1_enable_n     : std_logic     := '0';

  signal sram_bus_data_2_inout : sram_bus_data_t;
  signal sram_bus_control_2_out : sram_bus_control_t;

  signal sram_bus_2_lb_out_n : std_logic := '0';
  signal sram_bus_2_ub_out_n : std_logic := '0';
  signal sram_2_enable_n     : std_logic := '0';

  signal comm_instruction_data_out : word_t;
  signal comm_instruction_address_out : std_logic_vector(INSTRUCTION_ADDRESS_WIDTH - 1 downto 0);
  signal comm_instruction_write_enable_out : std_logic;
  signal comm_instruction_address_hi_select_out : std_logic;

  signal comm_kernel_start_out: std_logic;
  signal comm_kernel_address_out: instruction_address_t;
  signal comm_kernel_number_of_threads_out: thread_id_t;

  signal comm_constant_address_out: std_logic_vector(CONSTANT_MEM_LOG_SIZE - 1 downto 0);
  signal comm_constant_write_enable_out: std_logic;
  signal comm_constant_out: word_t;

  -- Clocks
  signal clock_sys  : std_logic;
  signal clock_25   : std_logic;
  signal clock_125  : std_logic;
  signal clock_125n : std_logic;

  -- Communication unit SRAM signals
  signal comm_sram_bus_data_1_in : sram_bus_data_t;
  signal comm_sram_bus_data_1_out : sram_bus_data_t;
  signal comm_sram_bus_data_2_in : sram_bus_data_t;
  signal comm_sram_bus_data_2_out : sram_bus_data_t;
  signal comm_sram_bus_control_1_out : sram_bus_control_t;
  signal comm_sram_bus_control_2_out : sram_bus_control_t;
  signal comm_memory_request_out : std_logic;


  -- LSU  SRAM signals
  signal load_store_sram_bus_data_1_in : sram_bus_data_t;
  signal load_store_sram_bus_data_1_out : sram_bus_data_t;
  signal load_store_sram_bus_data_2_in : sram_bus_data_t;
  signal load_store_sram_bus_data_2_out : sram_bus_data_t;
  signal load_store_sram_bus_control_1_out : sram_bus_control_t;
  signal load_store_sram_bus_control_2_out : sram_bus_control_t;
  signal load_store_memory_request_out : std_logic;


  -- HDMI  SRAM signals
  signal hdmi_sram_bus_data_1_in : sram_bus_data_t;
  signal hdmi_sram_bus_data_2_in : sram_bus_data_t;
  signal hdmi_sram_bus_control_1_out : sram_bus_control_t;
  signal hdmi_sram_bus_control_2_out : sram_bus_control_t;
  signal hdmi_sram_request_accepted_in : std_logic;
  
  
  -- SRAM out
  
  signal sram_bus_data_1_inout_i  : sram_bus_data_t;
  signal sram_bus_control_1_out_i : sram_bus_control_t;
  
  signal sram_bus_data_2_inout_i  : sram_bus_data_t;
  signal sram_bus_control_2_out_i : sram_bus_control_t;
  
  signal reset : std_logic := '0';

begin

  --Output system clock for testing and debugging
  
--  clock_output: ODDR2 port map ( d0 => '1', d1 => '0', c0 => clock_sys, c1 => not clock_sys, q => clk_sys_out);
--  clk_sys_out <= clock_sys;
  sram_1_enable_n <= '0';
  sram_2_enable_n <= '0';
  
--  debug_signal0 <= sram_bus_control_1_out.write_enable_n;
--  debug_signal1 <= load_store_sram_bus_control_1_out.write_enable_n;
--  debug_signal2 <= load_store_memory_request_out;
  
  sram_bus_control_1_out <= sram_bus_control_1_out_i;
  sram_bus_data_1_inout <= sram_bus_data_1_inout_i;
  sram_bus_control_2_out <= sram_bus_control_2_out_i;
  sram_bus_data_2_inout <= sram_bus_data_2_inout_i;
  
  ghettocuda : entity work.ghettocuda
  port map ( -- Stuff
            clk => clock_sys,
            reset => reset,

            -- Constant memory
            constant_write_data_in => comm_constant_out,
            constant_write_enable_in => comm_constant_write_enable_out,
            constant_write_address_in => comm_constant_address_out,

            -- Instruction memory
            instruction_memory_data_in => comm_instruction_data_out,
            instruction_memory_address_in => comm_instruction_address_out,
            instruction_memory_write_enable_in => comm_instruction_write_enable_out,
            instruction_memory_address_hi_select_in => comm_instruction_address_hi_select_out,

            -- Thread spawner
            ts_kernel_start_in => comm_kernel_start_out,
            ts_kernel_address_in => comm_kernel_address_out,
            ts_num_threads_in => comm_kernel_number_of_threads_out,
            ts_kernel_complete_out => mc_kernel_complete_out,

            -- LSU
            load_store_sram_bus_data_1_inout => load_store_sram_bus_data_1_inout,
            load_store_sram_bus_control_1_out => load_store_sram_bus_control_1_out,
            load_store_sram_bus_data_2_inout => load_store_sram_bus_data_2_inout,
            load_store_sram_bus_control_2_out => load_store_sram_bus_control_2_out,
            load_store_memory_request_out => load_store_memory_request_out,
            
            debug_signal0 => debug_signal0,
            debug_signal1 => debug_signal1,
            debug_signal2 => debug_signal2,
            -- Generic IO
            led_1_out => led_1_out,
            led_2_out => led_2_out);

  communication_unit : entity work.communication_unit
  generic map(
               CONSTANT_ADDRESS_WIDTH => CONSTANT_MEM_LOG_SIZE
  )
  port map(
            clk => clock_sys,

            ebi_data_inout => ebi_data_inout,
            ebi_control_in => ebi_control_in,

            instruction_data_out => comm_instruction_data_out,
            instruction_address_out => comm_instruction_address_out,
            instruction_write_enable_out => comm_instruction_write_enable_out,
            instruction_address_hi_select_out => comm_instruction_address_hi_select_out,

            sram_bus_data_1_inout => comm_sram_bus_data_1_inout,
            sram_bus_data_2_inout => comm_sram_bus_data_2_inout,
            sram_bus_control_1_out => comm_sram_bus_control_1_out,
            sram_bus_control_2_out => comm_sram_bus_control_2_out,
            sram_request_out => comm_memory_request_out,

            kernel_number_of_threads_out => comm_kernel_number_of_threads_out,
            kernel_start_out => comm_kernel_start_out,
            kernel_address_out => comm_kernel_address_out,

            constant_address_out => comm_constant_address_out,
            constant_write_enable_out => comm_constant_write_enable_out,
            constant_out => comm_constant_out
          );

  sram_arbiter_1 : entity work.sram_arbiter
  port map( -- LSU wires
            lsu_sram_bus_control_in => load_store_sram_bus_control_1_out,
            lsu_sram_bus_data_in    => load_store_sram_bus_data_1_out,
            lsu_sram_bus_data_out   => load_store_sram_bus_data_1_in,
            lsu_mem_request_in        => load_store_memory_request_out,

            -- VGA / HDMI wires
            vga_hdmi_sram_bus_control_in => hdmi_sram_bus_control_1_out,
            vga_hdmi_sram_bus_data_out => hdmi_sram_bus_data_1_in,
            vga_hdmi_request_accepted_out => hdmi_sram_request_accepted_in,

            -- Communication unit wires
            comm_sram_bus_control_in => comm_sram_bus_control_1_out,
            comm_sram_bus_data_in    => comm_sram_bus_data_1_out,
            comm_sram_bus_data_out   => comm_sram_bus_data_1_in,
            comm_mem_request_in        => comm_memory_request_out,

            -- SRAM wires
            sram_bus_control_out => sram_bus_control_1_out_i,
            sram_bus_data_inout => sram_bus_data_1_inout_i
          );

  sram_arbiter_1 : entity work.sram_arbiter
  port map( -- LSU wires
            lsu_sram_bus_control_in => load_store_sram_bus_control_2_out,
            lsu_sram_bus_data_in    => load_store_sram_bus_data_2_out,
            lsu_sram_bus_data_out   => load_store_sram_bus_data_2_in,
            lsu_mem_request_in        => load_store_memory_request_out,

            -- VGA / HDMI wires
            vga_hdmi_sram_bus_control_in => hdmi_sram_bus_control_2_out,
            vga_hdmi_sram_bus_data_out   => hdmi_sram_bus_data_2_in,
            vga_hdmi_request_accepted_out => hdmi_sram_request_accepted_in,

            -- Communication unit wires
            comm_sram_bus_control_in => comm_sram_bus_control_2_out,
            comm_sram_bus_data_in    => comm_sram_bus_data_2_out,
            comm_sram_bus_data_out   => comm_sram_bus_data_2_in,
            comm_mem_request_in        => comm_memory_request_out,

            -- SRAM wires
            sram_bus_control_out => sram_bus_control_2_out_i,
            sram_bus_data_inout => sram_bus_data_2_inout_i
          );

  video_unit : entity work.video_unit
  port map( clock_sys           => clock_sys
          , clock_25            => clock_25  
          , clock_125           => clock_125 
          , clock_125n          => clock_125n
          , reset               => reset
          
          , starved             => led_1_out
          , front_buffer_select => mc_frame_buffer_select_in

          , ram_request_accepted=> hdmi_sram_request_accepted_in
          , ram_0_bus_control   => hdmi_sram_bus_control_1_out 
          , ram_0_bus_data      => hdmi_sram_bus_data_1_inout 
          , ram_1_bus_control   => hdmi_sram_bus_control_2_out
          , ram_1_bus_data      => hdmi_sram_bus_data_2_inout
          
          , hdmi_connector      => hdmi_connector_out
          );
          
   clock_unit : entity work.clock_unit
   port map ( clk_in1  => clk
            , clk_out1 => clock_sys
            , clk_out2 => clock_25
            , clk_out3 => clock_125
            , clk_out4 => clock_125n
            );
            
  fake_ram_0 : entity work.fake_ram
  generic map(init_value => '0')
  port map( clk => clock_sys, reset => reset,
            write_enable_n_in => sram_bus_control_1_out_i.write_enable_n,
            address_in => sram_bus_control_1_out_i.address,
            data_inout => sram_bus_data_1_inout_i);
            
  fake_ram_1 : entity work.fake_ram
  generic map(init_value => '1')
  port map( clk => clock_sys, reset => reset,
            write_enable_n_in => sram_bus_control_2_out_i.write_enable_n,
            address_in => sram_bus_control_2_out_i.address,
            data_inout => sram_bus_data_2_inout_i);
end Behavioral;
