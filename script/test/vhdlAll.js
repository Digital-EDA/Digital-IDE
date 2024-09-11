const { vhdlAll } = require('../../resources/hdlParser');

const testFile = '../Digital-Test/Verilog/dependence_test/test.vhd';

(async () => {
    const all = await vhdlAll(testFile);
    console.log(JSON.stringify(all, null, '  '));
    console.log('number of symbols:', all.content.length);
})();