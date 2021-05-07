library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;


entity BRAM is                     -- un sólo puerto
  generic(
    G_BITS    : natural := 16;          -- Bits
    G_DEPTH   : natural := 15;          -- Wide
    G_REG_OUT : string  := "false"
    );
  port(
    CLKA  : in  std_logic;              -- reloj de escritura
    CLKB  : in  std_logic;              -- reloj de lectura
    WEA   : in  std_logic;
    ADDRA : in  std_logic_vector(G_DEPTH-1 downto 0);  -- puerto de escritura - 57200 instancia todos los bloques RAM
    ADDRB : in  std_logic_vector(G_DEPTH-1 downto 0);  -- puerto de lectura - 28800 pretende agrupar una cámara
    DIA   : in  std_logic_vector(G_BITS-1 downto 0);
    DOA   : out std_logic_vector(G_BITS-1 downto 0);
    DOB   : out std_logic_vector(G_BITS-1 downto 0)
    );
end BRAM;

architecture BlockRam of BRAM is

  type tipo_RAM is array (integer range 0 to (2**G_DEPTH)-1) of std_logic_vector(G_BITS-1 downto 0);  --type INT_ARRAY is array (integer range <>)
  signal RAM                                    : tipo_RAM;
  signal wr_op                                  : std_logic_vector(1 downto 0);
  signal w_addr, r_addr, w_ptr_next, w_ptr_succ : unsigned(G_DEPTH-1 downto 0);
  signal w_data, r_dataA, r_dataB               : std_logic_vector(G_BITS-1 downto 0);

begin

  w_data <= DIA;

  w_addr <= unsigned(ADDRA);
  r_addr <= unsigned(ADDRB);

  process(CLKA)
  begin
    if rising_edge(CLKA) then
      if WEA = '1' then
        RAM(to_integer(w_addr)) <= w_data;  -- Entran datos a ritmo de CLKA-> PIXEL CLOCK
        r_dataA                 <= w_data;  -- r_data <= w_data --> write first mode
      else
        -- read port
        r_dataA <= RAM(to_integer(w_addr));  -- -- si uso w_data y r_data se crea doble puerto
      end if;
    end if;
  end process;


  process(CLKB)
  begin
    if rising_edge(CLKB) then
      -- read port
      r_dataB <= RAM(to_integer(r_addr));  -- -- si uso w_data y r_data se crea doble puerto
    end if;
  end process;

  GEN_OUTPUT_REG : if G_REG_OUT = "true" generate
    process(CLKA)
    begin
      if rising_edge(CLKA) then
        DOA <= r_dataA;
      end if;
    end process;
    --
    process(CLKB)
    begin
      if rising_edge(CLKB) then
        DOB <= r_dataB;
      end if;
    end process;
  --
  end generate GEN_OUTPUT_REG;

  GEN_OUTPUT : if G_REG_OUT = "false" generate

    DOA <= r_dataA;
    DOB <= r_dataB;
  end generate GEN_OUTPUT;


end BlockRAM;


architecture LUTRAM of BRAM is

  type tipo_RAM is array (integer range 0 to (2**G_DEPTH)-1) of std_logic_vector(G_BITS-1 downto 0);  --type INT_ARRAY is array (integer range <>)
  signal RAM                                    : tipo_RAM;
  signal w_addr, r_addr  : unsigned(G_DEPTH-1 downto 0);

begin

  w_addr <= unsigned(ADDRA);
  r_addr <= unsigned(ADDRB);

  process(CLKA)
  begin
    if rising_edge(CLKA) then
      if WEA = '1' then
        RAM(to_integer(w_addr)) <= DIA;  -- Entran datos a ritmo de CLKA-> PIXEL CLOCK
      end if;
    end if;
  end process;
  

 DOA <= RAM(to_integer(w_addr));  -- -- si uso w_data y r_data se crea doble puerto
 DOB <= RAM(to_integer(r_addr));  -- -- si uso w_data y r_data se crea doble puerto



end LUTRAM;


