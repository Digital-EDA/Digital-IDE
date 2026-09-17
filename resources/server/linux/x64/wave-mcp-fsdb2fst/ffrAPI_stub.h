/*
 * ffrAPI.h : minimal stub of the Verdi FsdbReader (ffrAPI) header.
 *
 * NOT the real Synopsys header. Used ONLY for an offline compile check of
 * fsdb2fst.cpp on machines without a Verdi installation:
 *
 *   g++ -DFFRAPI_STUB -Ithird_party/fsdb2fst -c third_party/fsdb2fst/fsdb2fst.cpp
 *
 * Signatures mirror the subset of ffrAPI exercised by fsdb2fst.cpp (which
 * compiles against real FsdbReader headers), so a clean
 * compile here validates our usage against that API shape. The real build
 * must use the genuine $VERDI_HOME/share/FsdbReader/ffrAPI.h; this stub
 * never ships in that build and is harmless if the include order picks it
 * only when -DFFRAPI_STUB is passed.
 */
#ifndef FFR_API_STUB_H
#define FFR_API_STUB_H

#include <stdint.h>

typedef uint8_t  byte_T;
typedef uint32_t uint_T;
typedef int      bool_T;
typedef const char *str_T;

#ifndef TRUE
#define TRUE 1
#endif
#ifndef FALSE
#define FALSE 0
#endif

typedef int     fsdbRC;
#define FSDB_RC_SUCCESS   0
#define FSDB_RC_FAILURE  (-1)

typedef uint32_t fsdbVarIdcode;
typedef uint32_t fsdbSeqNum;
/* real ffrAPI: fsdbXTag is layout-identical to fsdbTag64 (the converter
 * casts between them) */
typedef struct fsdbTag64 { uint_T H; uint_T L; } fsdbTag64;
typedef fsdbTag64 fsdbXTag;

/* per-bit byte codes used by ffrGetVC for 1-byte-per-bit vars */
#define FSDB_BT_VCD_0 0
#define FSDB_BT_VCD_1 1
#define FSDB_BT_VCD_X 2
#define FSDB_BT_VCD_Z 3

/* VHDL-std_(u)logic byte codes (only relevant for dtidcode!=0 vars) */
#define FSDB_BT_VHDL_STD_LOGIC_U 0
#define FSDB_BT_VHDL_STD_LOGIC_X 1
#define FSDB_BT_VHDL_STD_LOGIC_0 2
#define FSDB_BT_VHDL_STD_LOGIC_1 3
#define FSDB_BT_VHDL_STD_LOGIC_Z 4
#define FSDB_BT_VHDL_STD_LOGIC_W 5
#define FSDB_BT_VHDL_STD_LOGIC_L 6
#define FSDB_BT_VHDL_STD_LOGIC_H 7
#define FSDB_BT_VHDL_STD_LOGIC_DASH 8

/* FSDB variable types (subset of the real fsdbShr enum).
 * MIDDLE=64 / COMPUTED=128 are flag bits OR-ed onto the base type. */
enum {
    FSDB_VT_VCD_EVENT       = 0,
    FSDB_VT_VCD_INTEGER     = 1,
    FSDB_VT_VCD_PARAMETER   = 2,
    FSDB_VT_VCD_REAL        = 3,
    FSDB_VT_VCD_REG         = 5,
    FSDB_VT_VCD_SUPPLY0     = 6,
    FSDB_VT_VCD_SUPPLY1     = 7,
    FSDB_VT_VCD_TIME        = 8,
    FSDB_VT_VCD_TRI         = 9,
    FSDB_VT_VCD_TRIAND      = 10,
    FSDB_VT_VCD_TRIOR       = 11,
    FSDB_VT_VCD_TRIREG      = 12,
    FSDB_VT_VCD_TRI0        = 13,
    FSDB_VT_VCD_TRI1        = 14,
    FSDB_VT_VCD_WAND        = 15,
    FSDB_VT_VCD_WIRE        = 16,
    FSDB_VT_VCD_WOR         = 17,
    FSDB_VT_VCD_REG2        = 20,
    /* VHDL std_logic / std_ulogic vars show up as these two when dtidcode
     * is non-zero. The exact enum values live in Verdi's real fsdbShr.h
     * (not redistributed); in the stub they only have to satisfy
     * IsConvertibleVar in fsdb2fst.cpp. */
    FSDB_VT_VHDL_SIGNAL     = 26,
    FSDB_VT_VHDL_VARIABLE   = 27,
    /* Some non-convertible types that show up in real FSDBs. */
    FSDB_VT_STREAM          = 64,     /* transaction stream vars */
    FSDB_VT_ESD_OPTION      = 129,    /* $$ESD_OPTIONS.* */
    FSDB_VT_MIDDLE          = 64,     /* verilog/vhdl flag bit */
    FSDB_VT_COMPUTED        = 128,    /* verilog/vhdl flag bit */
    FSDB_VT_MC_MASK         = (FSDB_VT_MIDDLE | FSDB_VT_COMPUTED)
};

enum fsdbBytesPerBit {
    FSDB_BYTES_PER_BIT_1B = 0,
    FSDB_BYTES_PER_BIT_2B = 1,
    FSDB_BYTES_PER_BIT_4B = 2,
    FSDB_BYTES_PER_BIT_8B = 3
};

enum fsdbTreeCBType {
    FSDB_TREE_CBT_UNKNOWN = 0,
    FSDB_TREE_CBT_BEGIN_TREE = 1,
    FSDB_TREE_CBT_END_TREE = 2,
    FSDB_TREE_CBT_SCOPE   = 3,
    FSDB_TREE_CBT_UPSCOPE = 4,
    FSDB_TREE_CBT_VAR     = 5,
    FSDB_TREE_CBT_END_ALL_TREE = 6
};

typedef struct {
    char *name;
    uint_T type;
} fsdbTreeCBDataScope;

typedef struct {
    char *name;
    union { uint_T idcode; } u;
    int32_t lbitnum;
    int32_t rbitnum;
    uint_T bytes_per_bit;
    uint_T direction;
    uint_T type;
    uint_T dtidcode;   /* non-zero for real VHDL-typed vars (std_logic, enum) */
} fsdbTreeCBDataVar;

typedef bool_T (*fsdbTreeCBFuncT)(fsdbTreeCBType, void *, void *);

struct ffrVCTrvsHdl_t {
    fsdbRC ffrHasIncoreVC(void);
    fsdbRC ffrGotoXTag(void *tag);
    fsdbRC ffrGotoNextVC(void);
    fsdbRC ffrGotoPrevVC(void);
    fsdbRC ffrGetXTag(void *tag);
    fsdbRC ffrGetVC(byte_T **vc);
    fsdbRC ffrGetMaxXTag(void *tag);
    void   ffrFree(void);
};

struct ffrTimeBasedVCTrvsHdl_t {
    fsdbRC ffrGotoNextVC(void);
    fsdbRC ffrGetVarIdcodeXTagVCSeqNum(fsdbVarIdcode *id, fsdbXTag *xtag,
                                       byte_T **vc, fsdbSeqNum *seq);
    void   ffrFree(void);
};

typedef ffrVCTrvsHdl_t        *ffrVCTrvsHdl;
typedef ffrTimeBasedVCTrvsHdl_t *ffrTimeBasedVCTrvsHdl;

#define FSDB_MIN_VAR_IDCODE 1

class ffrObject {
public:
    static bool_T   ffrIsFSDB(str_T fname);
    static ffrObject *ffrOpen3(str_T fname);
    static str_T    stub_path;      /* when set, ffrIsFSDB/ffrOpen3 serve a stub script */

    str_T     ffrGetScaleUnit(void);
    void      ffrSetTreeCBFunc(fsdbTreeCBFuncT cb, void *client_data);
    fsdbRC    ffrReadScopeVarTree(void);
    fsdbRC    ffrAddToSignalList(fsdbVarIdcode id);
    fsdbRC    ffrLoadSignals(void);
    fsdbRC    ffrUnloadSignals(void);
    ffrVCTrvsHdl ffrCreateVCTraverseHandle(fsdbVarIdcode id);
    ffrTimeBasedVCTrvsHdl ffrCreateTimeBasedVCTrvsHdl(uint_T n,
                                                      fsdbVarIdcode *ids);
    fsdbRC    ffrGetMaxVarIdcode(void);
    fsdbRC    ffrGetMaxFsdbTag64(fsdbTag64 *tag);
    fsdbRC    ffrClose(void);
};

#endif  /* FFR_API_STUB_H */
