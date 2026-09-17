/* ffrAPI stub implementation with scriptable behaviour, for offline
 * end-to-end tests of fsdb2fst on machines without a Verdi install.
 *
 * Env-driven modes:
 *   FSDB2FST_STUB_SCRIPT=<file>  script that describes the fake FSDB:
 *     scale <unit>                scale unit string
 *     tree begin|end|scope N|upscope|var NAME LEN BPB
 *     vc <tick> <id> <value chars>
 *   Without the env, every entry fails exactly like before.
 *
 * The script runner is intentionally tiny; it exists to reproduce and verify
 * the tree-callback and value-chunking behaviour we saw on the Verdi machine.
 */
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <map>
#include <string>
#include <vector>

#include "ffrAPI_stub.h"

str_T ffrObject::stub_path = NULL;

namespace {

struct StubVar {
    std::string name;
    unsigned int len = 1;
    unsigned int bpb = 0;   /* 0=1B 1=2B 2=4B 3=8B */
    unsigned int dir = 0;
    unsigned int type = 15; /* wire */
    fsdbVarIdcode id = 0;
};

struct StubVC {
    unsigned long long tick = 0;
    fsdbVarIdcode id = 0;
    std::string val;        /* ascii chars for 1B vars, or "3.14" for reals */
};

struct StubState {
    std::string scale = "1ns";
    std::vector<std::string> path;         /* script file path tokens */
    std::vector<StubVar> vars;
    std::vector<StubVC> vcs;
};

StubState *g_state = NULL;
fsdbTreeCBFuncT g_cb = NULL;
void *g_cb_data = NULL;

/* Fire the tree callback sequence: BEGIN_TREE, then the script's tree events
 * in order, END_TREE, then a second skeleton tree (BEGIN_TREE, SCOPE top_tb,
 * UPSCOPE, END_TREE, END_ALL_TREE). This mirrors what the Verdi machine test
 * observed on a real file (report 5.1). */
void fire_tree(void) {
    if (!g_cb || !g_state) return;
    bool_T cb_stop = TRUE;
    (void)cb_stop;

    fsdbTreeCBType t;
    t = FSDB_TREE_CBT_BEGIN_TREE; g_cb(t, g_cb_data, NULL);

    std::vector<std::string> stack;
    for (const std::string &line : g_state->path) {
        if (line == "upscope") {
            if (!stack.empty()) stack.pop_back();
            t = FSDB_TREE_CBT_UPSCOPE; g_cb(t, g_cb_data, NULL);
        } else if (line.rfind("scope ", 0) == 0) {
            fsdbTreeCBDataScope s;
            static std::string scope_hold;
            scope_hold = line.substr(6);
            s.name = const_cast<char *>(scope_hold.c_str());
            s.type = 1; /* module-ish */
            t = FSDB_TREE_CBT_SCOPE; g_cb(t, g_cb_data, &s);
            stack.push_back(scope_hold);
        } else if (line.rfind("var ", 0) == 0) {
            /* var NAME LEN BPB [DIR [TYPE [DTID]]] */
            StubVar v;
            char nbuf[512];
            uint_T dtid = 0;
            int n = sscanf(line.c_str(), "var %511s %u %u %u %u %u",
                        nbuf, &v.len, &v.bpb, &v.dir, &v.type, &dtid);
            if (n >= 3 && n <= 5) {
                v.name = nbuf;
            } else {
                continue;
            }
            v.id = static_cast<fsdbVarIdcode>(g_state->vars.size() + 1);
            g_state->vars.push_back(v);

            fsdbTreeCBDataVar d;
            static std::string name_hold;
            name_hold = v.name;
            d.name = const_cast<char *>(name_hold.c_str());
            d.u.idcode = v.id;
            d.lbitnum = static_cast<int32_t>(v.len) - 1;
            d.rbitnum = 0;
            d.bytes_per_bit = v.bpb;
            d.direction = v.dir;
            d.type = v.type;
            d.dtidcode = dtid;
            t = FSDB_TREE_CBT_VAR; g_cb(t, g_cb_data, &d);
        }
        /* "begin"/"end" lines in the script's tree list are ignored here;
         * BEGIN/END_TREE are emitted around the whole sequence. */
    }

    t = FSDB_TREE_CBT_END_TREE; g_cb(t, g_cb_data, NULL);

    /* second skeleton tree, as observed on the real file */
    t = FSDB_TREE_CBT_BEGIN_TREE; g_cb(t, g_cb_data, NULL);
    {
        static std::string top = "top_tb";
        fsdbTreeCBDataScope s;
        s.name = const_cast<char *>(top.c_str());
        s.type = 1;
        t = FSDB_TREE_CBT_SCOPE; g_cb(t, g_cb_data, &s);
        t = FSDB_TREE_CBT_UPSCOPE; g_cb(t, g_cb_data, NULL);
    }
    t = FSDB_TREE_CBT_END_TREE; g_cb(t, g_cb_data, NULL);
    t = FSDB_TREE_CBT_END_ALL_TREE; g_cb(t, g_cb_data, NULL);
}

}  // namespace

bool_T ffrObject::ffrIsFSDB(str_T fname) {
    /* Stub activation: the main program cannot know about the stub, so the
     * first ffrIsFSDB() call turns stub mode on. The real script path comes
     * from FSDB2FST_STUB_SCRIPT. */
    if (!stub_path) stub_path = fname ? fname : (str_T) "stub";
    (void)fname;
    return TRUE;
}

ffrObject *ffrObject::ffrOpen3(str_T) {
    if (!stub_path) return NULL;
    const char *script = std::getenv("FSDB2FST_STUB_SCRIPT");
    if (!script) return NULL;

    std::FILE *f = std::fopen(script, "r");
    if (!f) return NULL;

    g_state = new StubState();
    char line[1024];
    while (std::fgets(line, sizeof(line), f)) {
        if (line[0] == '#' || line[0] == '\n') continue;
        if (0 == strncmp(line, "scale ", 6)) {
            char buf[128];
            if (1 == sscanf(line + 6, "%127s", buf)) g_state->scale = buf;
        } else if (0 == strncmp(line, "vc ", 3)) {
            StubVC vc;
            char val[600];
            if (3 == sscanf(line + 3, "%llu %u %599[^\n]",
                            &vc.tick, &vc.id, val)) {
                vc.val = val;
                g_state->vcs.push_back(vc);
            }
        } else {
            g_state->path.push_back(std::string(line));
            /* strip trailing newline */
            std::string &s = g_state->path.back();
            while (!s.empty() && (s.back() == '\n' || s.back() == '\r'))
                s.pop_back();
        }
    }
    std::fclose(f);

    /* assign ids in var order (must match the vc ids used in the script) */
    unsigned int next = 1;
    for (StubVar &v : g_state->vars) v.id = next++;
    /* re-map: vars got ids by insertion order above; re-walk to keep var ids
     * stable if the script's tree list contains vars already */
    return new ffrObject();
}

str_T ffrObject::ffrGetScaleUnit(void) {
    static std::string hold;
    hold = g_state ? g_state->scale : std::string("1ns");
    return hold.c_str();
}

void ffrObject::ffrSetTreeCBFunc(fsdbTreeCBFuncT cb, void *client_data) {
    g_cb = cb;
    g_cb_data = client_data;
}

fsdbRC ffrObject::ffrReadScopeVarTree(void) {
    fire_tree();
    return FSDB_RC_SUCCESS;
}

fsdbRC ffrObject::ffrAddToSignalList(fsdbVarIdcode) { return FSDB_RC_SUCCESS; }

fsdbRC ffrObject::ffrLoadSignals(void) {
    /* register the time-based traverse handle content */
    return FSDB_RC_SUCCESS;
}

fsdbRC ffrObject::ffrUnloadSignals(void) { return FSDB_RC_SUCCESS; }

ffrVCTrvsHdl ffrObject::ffrCreateVCTraverseHandle(fsdbVarIdcode) {
    return NULL;
}

/* time-based traverse: emits (id, tick, value) in tick order, already
 * positioned on the first VC (mirrors the real API's documented behaviour) */
namespace {
struct StubTimeHdl : ffrTimeBasedVCTrvsHdl_t {
    size_t pos = 1;   /* the handle is created already positioned on VC #1 */
    std::vector<StubVC> *vcs = NULL;
    unsigned char byte_buf[8];
};
}

ffrTimeBasedVCTrvsHdl ffrObject::ffrCreateTimeBasedVCTrvsHdl(
    uint_T, fsdbVarIdcode *) {
    if (!g_state) return NULL;
    StubTimeHdl *h = new StubTimeHdl();
    h->vcs = &g_state->vcs;
    return h;
}

fsdbRC ffrTimeBasedVCTrvsHdl_t::ffrGotoNextVC(void) {
    StubTimeHdl *h = static_cast<StubTimeHdl *>(this);
    if (!h->vcs || h->pos >= h->vcs->size()) return FSDB_RC_FAILURE;
    h->pos++;
    return FSDB_RC_SUCCESS;
}

fsdbRC ffrTimeBasedVCTrvsHdl_t::ffrGetVarIdcodeXTagVCSeqNum(
    fsdbVarIdcode *id, fsdbXTag *xtag, byte_T **vc, fsdbSeqNum *) {
    StubTimeHdl *h = static_cast<StubTimeHdl *>(this);
    if (!h->vcs || h->pos == 0 || h->pos > h->vcs->size())
        return FSDB_RC_FAILURE;
    const StubVC &v = (*h->vcs)[h->pos - 1];
    *id = v.id;
    /* fsdbXTag is fsdbTag64-shaped: H = high 32 bits of the tick */
    xtag->H = static_cast<uint_T>(v.tick >> 32);
    xtag->L = static_cast<uint_T>(v.tick & 0xFFFFFFFFu);
    /* value buffer: for 1B vars it is len ascii chars; for reals we cheat by
     * parsing the double text into 8 bytes */
    if (v.val.size() <= sizeof(h->byte_buf) || true) {
        /* the converter reads exactly sig.len bytes for 1B vars; provide a
         * large static buffer to be safe */
        static unsigned char big[65536];
        std::memset(big, 0, sizeof(big));
        unsigned char as_bytes[8];
        std::memset(as_bytes, 0, 8);
        /* "f:<number>" parses as a float for 4B signals or a double for
         * 8B signals, matching the real FSDB binary layout. Without the
         * prefix, value chars land in the low bytes so the bit pattern
         * stays visible in hex dumps and in the FST binary block. */
        {
            unsigned int var_bpb = 0;
            for (const StubVar &sv : g_state->vars)
                if (sv.id == v.id) { var_bpb = sv.bpb; break; }
            if (v.val.rfind("f:", 0) == 0) {
                double parsed = std::strtod(v.val.c_str() + 2, NULL);
                if (var_bpb == 2) {          /* FSDB_BYTES_PER_BIT_4B */
                    float f = static_cast<float>(parsed);
                    std::memcpy(as_bytes, &f, sizeof(f));
                } else {                     /* FSDB_BYTES_PER_BIT_8B */
                    std::memcpy(as_bytes, &parsed, sizeof(parsed));
                }
            } else {
                for (unsigned int rb = 0; rb < v.val.size() && rb < 8; rb++)
                    as_bytes[rb] = static_cast<unsigned char>(v.val[rb]);
            }
        }
        /* if the value text is exactly len chars of 0/1/x/z treat as bits */
        bool bits = !v.val.empty();
        for (char c : v.val)
            if (c != '0' && c != '1' && c != 'x' && c != 'z' &&
                c != 'X' && c != 'Z') { bits = false; break; }
        /* the value text uses 0/1/x/z chars; the real ffrAPI hands FSDB
         * byte codes (FSDB_BT_VCD_*), so translate text -> byte codes.
         * Reals: 4B signals store 4-byte floats, 8B signals 8-byte
         * doubles (matches the real FSDB layout). The stub always fills
         * 8 bytes; the converter's EMIT_REAL reads 4 or 8 per the
         * signal's bytes_per_bit. */
        if (bits) {
            /* FSDB per-bit arrays are MSB-first (same order as the VCD value
             * string fstapi expects; the converter maps
             * vc[i] -> s[i] directly). Script text is MSB-first too, so this
             * is a straight text->bytecode translation. */
            for (size_t k = 0; k < v.val.size(); k++) {
                switch (v.val[k]) {
                case '0': big[k] = FSDB_BT_VCD_0; break;
                case '1': big[k] = FSDB_BT_VCD_1; break;
                case 'x': case 'X': big[k] = FSDB_BT_VCD_X; break;
                case 'z': case 'Z': big[k] = FSDB_BT_VCD_Z; break;
                default:  big[k] = FSDB_BT_VCD_X; break;
                }
            }
        } else {
            std::memcpy(big, as_bytes, 8);
        }
        *vc = big;
        return FSDB_RC_SUCCESS;
    }
    return FSDB_RC_FAILURE;
}

void ffrTimeBasedVCTrvsHdl_t::ffrFree(void) {}

fsdbRC ffrObject::ffrGetMaxVarIdcode(void) { return FSDB_RC_FAILURE; }
fsdbRC ffrObject::ffrGetMaxFsdbTag64(fsdbTag64 *) { return FSDB_RC_FAILURE; }
fsdbRC ffrObject::ffrClose(void) { return FSDB_RC_SUCCESS; }

fsdbRC ffrVCTrvsHdl_t::ffrHasIncoreVC(void) { return FALSE; }
fsdbRC ffrVCTrvsHdl_t::ffrGotoXTag(void *) { return FSDB_RC_FAILURE; }
fsdbRC ffrVCTrvsHdl_t::ffrGotoPrevVC(void) { return FSDB_RC_FAILURE; }
fsdbRC ffrVCTrvsHdl_t::ffrGetXTag(void *) { return FSDB_RC_FAILURE; }
fsdbRC ffrVCTrvsHdl_t::ffrGetVC(byte_T **) { return FSDB_RC_FAILURE; }
fsdbRC ffrVCTrvsHdl_t::ffrGetMaxXTag(void *) { return FSDB_RC_FAILURE; }
void ffrVCTrvsHdl_t::ffrFree(void) {}
