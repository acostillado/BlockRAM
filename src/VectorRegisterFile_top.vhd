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


entity VectorRegisterFile is
  generic(
    N_VELEMENTS : integer := 16;
    N_BITS      : integer := 64
    );
  port (
    sysclk0_clk_n : in std_logic;
    sysclk0_clk_p : in std_logic;
    HBM_CATTRIP   : out std_logic
   -- check boundaries.
    );
end VectorRegisterFile;

architecture RTL of VectorRegisterFile is

  component system is
    port (
      sysclk0_clk_n     : in  std_logic;
      sysclk0_clk_p     : in  std_logic;
      BRAM_PORTA_0_addr : out std_logic_vector (14 downto 0);
      BRAM_PORTA_0_clk  : out std_logic;
      BRAM_PORTA_0_din  : out std_logic_vector (511 downto 0);
      BRAM_PORTA_0_dout : in  std_logic_vector (511 downto 0);
      BRAM_PORTA_0_en   : out std_logic;
      BRAM_PORTA_0_rst  : out std_logic;
      BRAM_PORTA_0_we   : out std_logic_vector (63 downto 0)
      );
  end component system;

  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------

  signal vrfDin_r     : std_logic_vector(N_VELEMENTS*N_BITS-1 downto 0) := (others => '0');
  signal vrfDout_r    : std_logic_vector(N_VELEMENTS*N_BITS-1 downto 0) := (others => '0');
  signal vrfAddrA_r   : std_logic_vector(4 downto 0)                   := (others => '0');
  signal vrfWrEn_r    : std_logic                                       := '0';
  --
  signal system_addrA : std_logic_vector(14 downto 0)                   := (others => '0');
  signal system_clk   : std_logic;
  signal system_din   : std_logic_vector(511 downto 0);
  signal system_dout  : std_logic_vector(511 downto 0);
  signal system_en    : std_logic;
  signal system_rst   : std_logic;
  signal system_wren  : std_logic_vector(63 downto 0);

begin

  system_i : component system
    port map (
      BRAM_PORTA_0_addr(14 downto 0)  => system_addrA(14 downto 0),
      BRAM_PORTA_0_clk                => system_clk,
      BRAM_PORTA_0_din(511 downto 0)  => system_din(511 downto 0),
      BRAM_PORTA_0_dout(511 downto 0) => system_dout(511 downto 0),
      BRAM_PORTA_0_en                 => system_en,
      BRAM_PORTA_0_rst                => system_rst,
      BRAM_PORTA_0_we(63 downto 0)    => system_wren(63 downto 0),
      sysclk0_clk_n                   => sysclk0_clk_n,
      sysclk0_clk_p                   => sysclk0_clk_p
      );

  vrfAddrA_r <= system_addrA(4 downto 0);
  vrfWrEn_r  <= system_din(0);

  vrfDin_r <= system_din & system_din;

  system_dout <= vrfDout_r(511 downto 0);

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

end;
