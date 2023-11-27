const { vlogFast } = require('../../resources/hdlParser');

const testFile = 'c:/Users/11934/Project/Digital-IDE/Digital-Test/Verilog/dependence_test/head_1.v';

(async () => {
    const fast = await vlogFast(testFile);
    console.log(JSON.stringify(fast, null, '  '));
})();