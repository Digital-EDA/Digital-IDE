const { vlogFast, callParser } = require('../../resources/hdlParser');

const testFile = '../Digital-Test/user/src/netlist_test.v';

(async () => {
    const fast = await vlogFast(testFile);
    console.log(JSON.stringify(fast, null, '  '));
})();