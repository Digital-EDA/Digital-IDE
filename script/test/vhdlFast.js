const { vhdlFast } = require('../../resources/hdlParser');

const testFile = '../Digital-Test/Verilog/dependence_test/test.vhd';

(async () => {
    const fast = await vhdlFast(testFile);
    console.log(JSON.stringify(fast, null, '  '));
})();