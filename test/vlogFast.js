const { vlogFast } = require('../resources/hdlParser');

const testFile = 'c:/Users/11934/Project/Digital-IDE/Digital-Test/Verilog/dependence_test/parent.v';

(async () => {
    const fast = vlogFast(testFile);
    console.log(JSON.stringify(fast, null, '  '));
})();