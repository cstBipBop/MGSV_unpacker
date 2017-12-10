# MGSV_unpacker

.cmd file that makes use of Atvaark's tools for unpacking MGSV:TPP game files. config.txt uses simple boolean values for setting up the way the command file runs. Detailed individual tool creator info and links to their repositories will be added later, as well as detailed usage. lang and qar dictionaries are the result of modder community efforts.

# Usage

## Configuration

Adjust config.txt to your liking.

### Booleans

#### General

PullDats - automatically import any missing dats to unpack folder
Echo - Enable exe prompt feedback. Disabled by default. Enabling will slow performance, but is useful for debugging.

#### Folder skips

These take precedence over other variables. Setting any of these to enabled will cause the .cmd to skip unpacking an entire .dat or folder.

#### Tool skips

DatSkip - don't unpack dat files
FpkSkip - don't unpack fpk, pftxs, or sbp files
FoxSkip - don't run FoxTool.exe
LangSkip - don't unpack localization files (.lng, .subp, .ffnt)
DdsSkip - don't run FtexTool.exe

#### Tool on specific folder skips

Supersceded by enabled Tool skip variables.

Dat\_{n}Skip - Don't unpack .dat n
Fpk\_{n}Skip - Don't unpack fpk, fpkd archives in n
Fox\_{n}Skip - Don't run FoxTool.exe on n
Lang\_{n}Skip - Don't unpack localization files in n
Dds\_{n}Skip - Don't unpack .ftex, .ftexs files in n
