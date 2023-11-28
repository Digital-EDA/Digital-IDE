const { vhdlAll } = require('../../resources/hdlParser');

const testFile = '../Digital-Test/Verilog/dependence_test/test.vhd';

(async () => {
    const fast = await vhdlAll(testFile);
    console.log(JSON.stringify(fast, null, '  '));
})();