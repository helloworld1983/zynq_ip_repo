----------------------------------------------------------------------------------
-- Engineer: Jason Gutel
-- 
-- Create Date: 05/17/2017 09:20:37 AM
-- Design Name: 
-- Module Name: FIFO_Controller - Behavioral
-- Target Devices: Zynq7020
-- Tool Versions: Vivado 2015.4
-- Description:   Controller interface for BRAM block_memory_generator core
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
use IEEE.NUMERIC_STD.ALL;

entity FIFO_Controller is
    generic (
           BRAM_ADDR_WIDTH  : integer := 10;
           BRAM_DATA_WIDTH  : integer := 32 );
    Port ( 
           -- BRAM write port lines
           addra : out STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
           dina  : out STD_LOGIC_VECTOR (BRAM_DATA_WIDTH-1 downto 0);
           ena   : out STD_LOGIC;
           wea   : out STD_LOGIC;
           clka  : out std_logic;
           rsta  : out std_logic;
       
           -- BRAM read port lines
           addrb : out STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
           doutb : in STD_LOGIC_VECTOR (BRAM_DATA_WIDTH-1 downto 0);
           enb   : out STD_LOGIC;
           clkb  : out std_logic;
           rstb  : out std_logic;
           
           -- Core logic
           clk        : in std_logic;
           clkEn      : in std_logic;
           write_en   : in std_logic;
           read_en    : in std_logic;
           reset      : in std_logic;
           din        : in std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
           dout       : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
           dout_valid : out std_logic;
           bram_full  : out std_logic;
           bram_empty : out std_logic;
           bram_occupancy  : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0)
           );
end FIFO_Controller;

architecture Behavioral of FIFO_Controller is

    component addr_gen is
    generic ( BRAM_ADDR_WIDTH  : integer := 10 );
    Port ( clk : in STD_LOGIC;
           en  : in STD_LOGIC;
           rst : in STD_LOGIC;
           rden : in STD_LOGIC;
           wren : in STD_LOGIC;
           rd_addr : out STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
           wr_addr : out STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
           fifo_empty : out std_logic;
           fifo_full  : out std_logic;
           fifo_occupancy : out STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0));
    end component addr_gen;

    signal rd_addr : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');
    signal wr_addr : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');
    signal addr_rden, addr_wren : std_logic := '0';
    signal addr_full, addr_empty : std_logic := '0';    
        
    begin
    
        -- instantiate clock at top level with BUFR; leave this port open in instantiation
        clka <= clk;
        clkb <= clk;
	    ena <= '1' when (clkEn = '1') else '0';
	    enb <= '1' when (clkEn = '1') else '0';  
        
        bram_full <= addr_full;
        bram_empty <= addr_empty;
        
        fifo_addr_gen : addr_gen
        generic map ( BRAM_ADDR_WIDTH => BRAM_ADDR_WIDTH )
        port map(
            clk => clk,
            en  => clkEn,
            rst => reset,
            rden => addr_rden,
            wren => addr_wren,
            rd_addr => rd_addr,
            wr_addr => wr_addr,
            fifo_empty => addr_empty,
            fifo_full => addr_full,
            fifo_occupancy => bram_occupancy
        );
        
        bram_read : process(clk)
        begin
        if(rising_edge(clk)) then
            if(reset = '1') then
                dout_valid <= '0';
                rstb       <= '1';
            elsif(clkEn = '1') then
                rstb <= '0';
                if(read_en = '1' and addr_empty = '0') then
                    dout <= doutb;
                    dout_valid <= '1';
                    addr_rden  <= '1';
                else
                    addr_rden <= '0';
                end if;
            end if;
        end if;
        end process bram_read;
        
        bram_write : process(clk)
        begin
        if(rising_edge(clk)) then
            if(reset = '1') then
                wea       <= '0';
                rsta      <= '1';
                addr_wren <= '0';
            elsif(clkEn = '1') then
                rsta <= '0';
                if(write_en = '1' and addr_full = '0') then
                    dina <= din;
                    wea  <= '1';
                    addr_wren <= '1';
                else
                    wea <= '0';
                    addr_wren <= '0';
                end if;
            end if;
        end if;
        end process bram_write;
        
        addr_load : process(clk)
        begin
        if(rising_edge(clk)) then
            addra <= wr_addr;
            addrb <= rd_addr;
        end if;
        end process addr_load;
                    
    end Behavioral;
