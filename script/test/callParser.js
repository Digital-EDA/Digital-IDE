const { vlogFast, callParser } = require('../../resources/hdlParser');

const testFile = 'c:/Users/11934/Project/Digital-IDE/Digital-Test/user/src/netlist_test.v';

(async () => {
    const fast = await callParser(testFile, 5);
    console.log(fast);
    const all = await callParser(testFile, 6);
    console.log(all);
})();