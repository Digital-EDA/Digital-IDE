const { svAll } = require('../../resources/hdlParser');

const testFile = '../Digital-Test/svlog/user/src/hello.sv';

(async () => {
    const all = await svAll(testFile);
    (JSON.stringify(all, null, '  '));
})();