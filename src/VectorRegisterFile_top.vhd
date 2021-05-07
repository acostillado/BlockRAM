-------------------------------------------------------------------------------
-- Company      : Line Buffer
-- Engineer    : Daniel Jiménez Mazure
-- *******************************************************************
-- File       : VRF.vhd
-- Author     : $Autor: dasjimaz@gmail.com $
-- Date       : $Date: 2021-04-30 $
-- Revisions  : $Revision: $
-- Last update: 2021-04-10
-- *******************************************************************
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Stores 3 lines. Controls the flow. Connects NKERNEL BRAMS in a
-- chain fashion
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.std_logic_misc.all;
use IEEE.NUMERIC_STD.all;
use IEEE.MATH_REAL.all;
use std.textio.all;
use ieee.std_logic_textio.all;

library UNISIM;
use UNISIM.VComponents.all;


entity VectorRegisterFile is
  generic(
    N_VELEMENTS : integer := 16;
    N_BITS      : integer := 64
    );
  port (
    sysclk0_clk_n : in std_logic;
    sysclk0_clk_p : in std_logic;
    UART_RX       : in std_logic;
    UART_TX       : out std_logic;
    HBM_CATTRIP   : out std_logic
   -- check boundaries.
    );
end VectorRegisterFile;

architecture RTL of VectorRegisterFile is

    constant C_ADDR : integer := 5;
    constant C_WR_EN : integer := 1;
  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------

  signal vrfDin_r     : std_logic_vector(N_VELEMENTS*N_BITS-1 downto 0) := (others => '0');
  signal vrfDout_r    : std_logic_vector(N_VELEMENTS*N_BITS-1 downto 0) := (others => '0');
  signal vrfAddrA_r   : std_logic_vector(4 downto 0)                   := (others => '0');
  signal vrfWrEn_r    : std_logic                                       := '0';
  signal system_clk   : std_logic                                      := '0';
  signal system_din   : std_logic_vector(C_WR_EN + N_VELEMENTS*N_BITS+C_ADDR-1 downto 0) := (others => '0');
  --
  signal shiftVrfOut  : std_logic_vector(N_VELEMENTS*N_BITS-1 downto 0) := (others => '0');
  signal uart_tx_r    : std_logic;

begin

   IBUFDS_inst : IBUFDS
   generic map (
      DIFF_TERM => FALSE, -- Differential Termination 
      IBUF_LOW_PWR => TRUE, -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
      IOSTANDARD => "DEFAULT")
   port map (
      O => system_clk,  -- Buffer output
      I => sysclk0_clk_p,  -- Diff_p buffer input (connect directly to top-level port)
      IB => sysclk0_clk_n -- Diff_n buffer input (connect directly to top-level port)
   );
   
   process(system_clk)
   begin
    if rising_edge(system_clk) then
        system_din <= system_din(C_WR_EN + N_VELEMENTS*N_BITS+C_ADDR-2 downto 0) & UART_RX;
        shiftVrfOut <= vrfDout_r(vrfDout_r'high-1 downto 0) & shiftVrfOut(shiftVrfOut'high);
        uart_tx_r <= shiftVrfOut(0);
    end if;
   end process;    

  vrfAddrA_r <= system_din(C_ADDR-1 downto 0);
  vrfWrEn_r  <= system_din(system_din'high);
  vrfDin_r  <= system_din(N_VELEMENTS*N_BITS+C_ADDR-1 downto C_ADDR);

  Inst_BRAM_VRF : entity work.BRAM
    generic map (
      G_BITS    => N_BITS * N_VELEMENTS,
      G_DEPTH   => 5,
      G_REG_OUT => "true"
      )
    port map (
      CLKA  => system_clk,
      CLKB  => system_clk,
      WEA   => vrfWrEn_r,
      ADDRA => vrfAddrA_r,
      ADDRB => (others => '0'),
      DIA   => vrfDin_r,
      DOA   => vrfDout_r,
      DOB   => open
      );
      
      HBM_CATTRIP <= '0';
      
      UART_TX <= uart_tx_r;

end;
