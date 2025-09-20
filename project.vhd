library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
entity mux is
    Port ( in0 : in std_logic_vector(15 downto 0);
           in1 : in std_logic_vector(15 downto 0);
           sel : in std_logic;
           dout : out std_logic_vector(15 downto 0));
end mux;
architecture mux_arch of mux is
begin
with sel select
    dout <= in0 when '0',
            in1 when '1',
            x"0000" when others;
end mux_arch;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
entity reg16 is
    Port ( clk : in std_logic;
           din : in STD_LOGIC_VECTOR (15 downto 0);
           load : in STD_LOGIC;
           rst : in STD_LOGIC;
           dout : out STD_LOGIC_VECTOR (15 downto 0)
    );
end reg16;
architecture reg16_arch of reg16 is
begin
    process(clk, rst)
    begin
        if rst = '1' then
            dout <= (others => '0');        -- mette tutti '0' (16 in totale)
        elsif clk'event and clk='1' then
            if load = '1' then
                dout <= din;
            end if;
        end if;
    end process;
end reg16_arch;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
entity fa is
    Port ( a : in STD_LOGIC;
           b : in STD_LOGIC;
           cin : in std_logic;
           dout : out STD_LOGIC;
           cout: out std_logic);
end fa;
architecture fa_arch of fa is
begin
    dout <= a xor b xor cin;
    cout <= (a and b) or ((a xor b) and cin);
end fa_arch;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
entity adder16 is
    Port ( a : in STD_LOGIC_VECTOR (15 downto 0);
           b : in STD_LOGIC_VECTOR (15 downto 0);
           dout : out STD_LOGIC_VECTOR (15 downto 0);
           cout : out std_logic);
end adder16;
architecture adder16_arch of adder16 is
    component fa is
        Port ( a : in STD_LOGIC;
               b : in STD_LOGIC;
               cin : in std_logic;
               dout : out STD_LOGIC;
               cout : out std_logic);
    end component;
    
    signal dout_temp: std_logic_vector(15 downto 0);
    signal cout_temp: std_logic_vector(16 downto 0);
    signal zero : std_logic := '0';
    
begin

    cout_temp(0) <= zero;
    fas_gen: for i in 0 to 15 generate
        fas : fa port map(a(i), b(i), cout_temp(i), dout(i), cout_temp(i+1));       -- "Genera" 16 fa con i giusti collegamenti
    end generate;
    cout <= cout_temp(16);

end adder16_arch;


-- FSM
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity fsm is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           start : in STD_LOGIC;
           done : in STD_LOGIC;
           l1 : out STD_LOGIC;
           s1 : out STD_LOGIC;
           l2 : out STD_LOGIC;
           s2 : out STD_LOGIC;
           s3 : out STD_LOGIC;
           en : out STD_LOGIC;
           s5 : out STD_LOGIC;
           mem_en : out STD_LOGIC;
           mem_we : out STD_LOGIC);
end fsm;

architecture fsm_arch of fsm is
    type S is (RESET, READY, INIT, FETCH, READ_VAL, WRITE1, WRITE2, FINISH, WAIT_START);
    signal curr_state: S;
begin

    process(clk, rst)
    begin
        if rst = '1' then
            curr_state <= RESET;
        elsif clk'event and clk = '1' then
           case curr_state is
                when RESET =>
                    if rst='0' then curr_state<=READY; end if;
                when READY =>
                    if start='1' then curr_state<=INIT; end if;
                when INIT => curr_state<=FINISH;
                when FETCH => curr_state<=READ_VAL;
                when READ_VAL => curr_state<=WRITE1;
                when WRITE1 => curr_state<=WRITE2;
                when WRITE2 => curr_state<=FINISH;
                when FINISH =>
                    if done='0' then curr_state<=FETCH;
                    else curr_state<=WAIT_START; end if;
                when WAIT_START =>
                    if start='0' then curr_state<=READY; end if;
           end case; 
        end if;  
    end process;
    
    process(curr_state)
    begin
        l1  <= '0';
        s1  <= '1';
        l2  <= '0';
        s2  <= '1';
        s3  <= '0';
        en  <= '0';
        s5  <= '0';
        mem_en  <= '1';
        mem_we  <= '0';
        
        if curr_state = RESET then
            mem_en <= '0';
        elsif curr_state = READY then
            mem_en <= '0';
        elsif curr_state = INIT then
            mem_en <= '0';
            s1 <= '0';
            s2 <= '0';
            l1 <= '1';
            l2 <= '1';
        elsif curr_state = READ_VAL then
            en <= '1';
        elsif curr_state = WRITE1 then
            mem_we <= '1';
            s5 <= '0';
            l1 <= '1';
        elsif curr_state = WRITE2 then
            mem_we <= '1';
            l1 <= '1';
            l2 <= '1';
            s5 <= '1';
        elsif curr_state = FINISH then
            mem_en <= '0';
            s3 <= '1';
        elsif curr_state = WAIT_START then
            mem_en <= '0';
            s3 <= '1';   
        end if;
    end process;
            
end fsm_arch;


-- Architettura che riunisce le altre componenti di supporto
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity project_reti_logiche is
    port (
        i_clk   : in std_logic;
        i_rst   : in std_logic;
        i_start : in std_logic;
        i_add   : in std_logic_vector(15 downto 0);
        i_k     : in std_logic_vector(9 downto 0);
        
        o_done  :out std_logic;
        
        o_mem_addr  : out std_logic_vector(15 downto 0);
        i_mem_data  : in std_logic_vector(7 downto 0);
        o_mem_data  : out std_logic_vector(7 downto 0);
        o_mem_we    : out std_logic;
        o_mem_en    : out std_logic
    );
end project_reti_logiche;

architecture project_reti_logiche_arch of project_reti_logiche is
    component mux is
        Port ( in0 : in std_logic_vector(15 downto 0);
               in1 : in std_logic_vector(15 downto 0);
               sel : in std_logic;
               dout : out std_logic_vector(15 downto 0));
    end component;
    component reg16 is
        Port ( clk : in std_logic;
               din : in STD_LOGIC_VECTOR (15 downto 0);
               load : in STD_LOGIC;
               rst : in STD_LOGIC;
               dout : out STD_LOGIC_VECTOR (15 downto 0)
        );
    end component;   
    component adder16 is
        Port ( a : in STD_LOGIC_VECTOR (15 downto 0);
               b : in STD_LOGIC_VECTOR (15 downto 0);
               dout : out STD_LOGIC_VECTOR (15 downto 0);
               cout : out std_logic);
    end component;       
    component fsm is
        Port ( clk : in STD_LOGIC;
               rst : in STD_LOGIC;
               start : in STD_LOGIC;
               done : in STD_LOGIC;
               l1 : out STD_LOGIC;
               s1 : out STD_LOGIC;
               l2 : out STD_LOGIC;
               s2 : out STD_LOGIC;
               s3 : out STD_LOGIC;
               en : out STD_LOGIC;
               s5 : out STD_LOGIC;
               mem_en : out STD_LOGIC;
               mem_we : out STD_LOGIC);
    end component;

    -- FSM
    signal load1, sel1, load2, sel2, sel3, en_reg, sel5: std_logic;

    -- Gestore dell'indirizzo di memoria
    signal reg_addr_in, reg_addr_out, reg_addr_incr: std_logic_vector(15 downto 0);
    
    -- Gestore del numero di iterazioni
    signal reg_k_in, reg_k_out, reg_k_decr: std_logic_vector(15 downto 0);
    signal o_done_tmp: std_logic;
    
    --- Registro valore, credibilità
    signal reg_val, reg_cred: std_logic_vector(7 downto 0);
    signal reg_cred_decr: std_logic_vector(15 downto 0);

begin
    
    -- Gestore FSM
    fsm_comp: fsm port map (i_clk, i_rst, i_start, o_done_tmp, load1, sel1, load2, sel2, sel3, en_reg, sel5, o_mem_en, o_mem_we);
    
    
    -- Gestore dell'indirizzo di memoria
    mux1: mux port map (i_add, reg_addr_incr, sel1, reg_addr_in);
    reg_addr: reg16 port map(i_clk, reg_addr_in, load1, i_rst,  reg_addr_out);
    incr1: adder16 port map (reg_addr_out, x"0001", reg_addr_incr, open);
    o_mem_addr <= reg_addr_out;
    
    
    -- Gestore del numero di iterazioni
    mux2: mux port map ("000000"&i_k, reg_k_decr, sel2, reg_k_in);
    reg_k: reg16 port map (i_clk, reg_k_in, load2, i_rst, reg_k_out);
    decr3: adder16 port map (reg_k_out, x"ffff", reg_k_decr, open);
    o_done <= o_done_tmp;
    
    process(reg_k_out, sel3)        -- se sono arrivato alla fine e sto controllando se ho finito (sel3='1'), allora metto o_done_tmp a '1'
    begin
        if sel3='1' and reg_k_out=x"0000" then
            o_done_tmp <= '1';
        else
            o_done_tmp <= '0';
        end if;
    end process;
    
    
    -- Registro valore, Registro credibilità, gestore scrittura in memoria
    -- Parte composta di 2 process e la parte Structural per decr4
    process(i_rst, i_clk, i_mem_data, en_reg, reg_cred_decr)
    -- Questo processo è attivo se siamo in fase di scrittura dei registri (en_reg='1').
    -- Si occupa di impostare i giusti valori di reg_val e reg_cred in base al valore letto (in i_mem_data)
    begin
        if i_rst = '1' then
            reg_val <= x"00";
            reg_cred <= x"00";
        elsif en_reg='1' and i_clk'event and i_clk='1' then
            if i_mem_data /= x"00" then
                reg_val <= i_mem_data;
            end if;
            if i_mem_data /= x"00" then
                reg_cred <= x"1f";
            elsif reg_cred /= x"00" then
                reg_cred <= reg_cred_decr(7 downto 0);
            end if;
        end if;
    end process;
    
    process(reg_val, reg_cred, sel5)
    -- Questo processo è un MUX per impostare il giusto valore da scrivere in memoria
    -- Si poteva fare anche Structural, visto il componente mux l'ho scritto...
    begin
        if sel5 = '0' then
            o_mem_data <= reg_val;
        else
            o_mem_data <= reg_cred;
        end if;
    end process;
    
    decr4: adder16 port map (x"00"&reg_cred, x"ffff", reg_cred_decr, open);    
    
end project_reti_logiche_arch;
