const { vlogAll } = require('../../resources/hdlParser');

const testFile = '../Digital-Test/user/src/netlist_test.v';

(async () => {
    const all = await vlogAll(testFile);
    console.log(JSON.stringify(all, null, '  '));
})();