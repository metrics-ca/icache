package elf_pkg;

typedef bit [7:0]   u8;
typedef bit [15:0]  u16;
typedef bit [31:0]  u32;
typedef bit [63:0]  u64;

typedef struct {
    u8      e_magic[4];
    u8      e_class;    // 1=32-bit 2=64-bit
    u8      e_endian;   // 1=little 2=big
    u8      e_pad[10];
    u16     e_type;
    u16     e_machine;
    u32     e_version;
    u64     e_entry;
    u64     e_phoff;
    u64     e_shoff;
    u32     e_flags;
    u16     e_ehsize;
    u16     e_phentsize;
    u16     e_phnum;
    u16     e_shentsize;
    u16     e_shnum;
    u16     e_shstrndx;
} Elf64_Ehdr;

static const u8 ELFMAG[4] = '{ 127,"E", "L", "F"};

typedef struct {
    u32     sh_name;
    u32     sh_type;
    u64     sh_flags;
    u64     sh_addr;
    u64     sh_offset;
    u64     sh_size;
    u32     sh_link;
    u32     sh_info;
    u64     sh_addralign;
    u64     sh_entsize;
} Elf64_Shdr;

typedef struct {
    u32     p_type;
    u32     p_flags;
    u64     p_offset;
    u64     p_vaddr;
    u64     p_paddr;
    u64     p_filesz;
    u64     p_memsz;
    u64     p_align;
} Elf64_Phdr;

static const int PT_LOAD = 1;

virtual class ElfMemory;
    pure virtual function void   write(u64 addr, bit [7:0] data[]);
endclass

class ElfFile;
//private:
    int                 m_FD;
    bit                 m_BE;
    bit                 m_OK;
    Elf64_Ehdr          m_Ehdr;
    Elf64_Phdr          m_Phdrs[$];
//public:
    extern function bit openFile(string name);
    extern function bit load(ElfMemory sink);
    function bit [63:0] get_entry(); return m_Ehdr.e_entry; endfunction 
    function bit ok(); return m_OK; endfunction
//private:

    extern function void read_ehdr(output Elf64_Ehdr hdr);
    extern function void read_phdr(output Elf64_Phdr hdr);
    extern function void read_u8(output u8 item);
    extern function void read_u16(output u16 item);
    extern function void read_u32(output u32 item);
    extern function void read_u64(output u64 item);

endclass

function bit ElfFile::openFile(string name);
    m_FD = $fopen(name, "rb");
$display("fd=%h", m_FD);
    m_OK = (m_FD != 0);
    read_ehdr(m_Ehdr);
    if (!m_OK) begin
        $display("ElfFile::openFile: failed.");
        return 0;
    end
    $fseek(m_FD, m_Ehdr.e_phoff, 0);
    for (int i = 0; i < m_Ehdr.e_phnum; i++) begin
        Elf64_Phdr hdr;

        read_phdr(hdr);
        m_Phdrs.push_back(hdr);
    end
    return m_OK;
endfunction

function bit ElfFile::load(ElfMemory sink);
    foreach (m_Phdrs[i]) begin
$display("phdr %d = %p", i, m_Phdrs[i]);
        if (m_Phdrs[i].p_type == PT_LOAD) begin
            bit [7:0] da[] = new[m_Phdrs[i].p_filesz];
            $fseek(m_FD, m_Phdrs[i].p_offset, 0);
            $fread(da, m_FD);
            sink.write(m_Phdrs[i].p_vaddr, da);
            if (m_Phdrs[i].p_memsz > m_Phdrs[i].p_filesz) begin
                da = new [m_Phdrs[i].p_memsz - m_Phdrs[i].p_filesz];
                sink.write(m_Phdrs[i].p_vaddr + m_Phdrs[i].p_filesz, da);
            end
        end
    end
    return m_OK;
endfunction

function void ElfFile::read_u8(output u8 item);
    int     c = $fgetc(m_FD);

    m_OK &= (c != -1);
    item = c;
endfunction

function void ElfFile::read_u16(output u16 item);
    if (m_BE) begin
        read_u8(item[15:8]);
        read_u8(item[7:0]);
    end else begin
        read_u8(item[7:0]);
        read_u8(item[15:8]);
    end
endfunction

function void ElfFile::read_u32(output u32 item);
    if (m_BE) begin
        read_u8(item[31:24]);
        read_u8(item[23:16]);
        read_u8(item[15:8]);
        read_u8(item[7:0]);
    end else begin
        read_u8(item[7:0]);
        read_u8(item[15:8]);
        read_u8(item[23:16]);
        read_u8(item[31:24]);
    end
endfunction

function void ElfFile::read_u64(output u64 item);
    if (m_BE) begin
        read_u8(item[63:56]);
        read_u8(item[55:48]);
        read_u8(item[47:40]);
        read_u8(item[39:32]);
        read_u8(item[31:24]);
        read_u8(item[23:16]);
        read_u8(item[15:8]);
        read_u8(item[7:0]);
    end else begin
        read_u8(item[7:0]);
        read_u8(item[15:8]);
        read_u8(item[23:16]);
        read_u8(item[31:24]);
        read_u8(item[39:32]);
        read_u8(item[47:40]);
        read_u8(item[55:48]);
        read_u8(item[63:56]);
    end
endfunction

function void ElfFile::read_ehdr(output Elf64_Ehdr hdr);
    foreach (hdr.e_magic[i]) read_u8(hdr.e_magic[0]);
    read_u8(hdr.e_class);
    if (hdr.e_class != 2) begin
        m_OK = 0;
        $display("ElfFile::read_ehdr: bad class %0d", hdr.e_class);
        return;
    end
    read_u8(hdr.e_endian);
    m_BE = (hdr.e_endian == 2);
    if (!hdr.e_endian inside { [1:2] }) begin
        m_OK = 0;
        $display("ElfFile::read_ehdr: bad endian %0d", hdr.e_endian);
        return;
    end
    foreach (hdr.e_pad[i]) read_u8(hdr.e_pad[i]);
    read_u16(hdr.e_type);
    read_u16(hdr.e_machine);
    read_u32(hdr.e_version);
    read_u64(hdr.e_entry);
    read_u64(hdr.e_phoff);
    read_u64(hdr.e_shoff);
    read_u32(hdr.e_flags);
    read_u16(hdr.e_ehsize);
    read_u16(hdr.e_phentsize);
    read_u16(hdr.e_phnum);
    read_u16(hdr.e_shentsize);
    read_u16(hdr.e_shnum);
    read_u16(hdr.e_shstrndx);
$display("ehdr: %p", hdr);
endfunction

function void ElfFile::read_phdr(output Elf64_Phdr hdr);
    read_u32(hdr.p_type);
    read_u32(hdr.p_flags);
    read_u64(hdr.p_offset);
    read_u64(hdr.p_vaddr);
    read_u64(hdr.p_paddr);
    read_u64(hdr.p_filesz);
    read_u64(hdr.p_memsz);
    read_u64(hdr.p_align);
    $display("read %p", hdr);
endfunction

endpackage
