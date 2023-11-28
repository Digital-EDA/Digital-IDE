const { vlogFast } = require('../../resources/hdlParser');

const testFile = '../Digital-Test/Verilog/dependence_test/head_1.v';

(async () => {
    const fast = await vlogFast(testFile);
    console.log(JSON.stringify(fast, null, '  '));
})();