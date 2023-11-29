const { vlogAll } = require('../../resources/hdlParser');

const testFile = '../Digital-Test/user/src/child_2.v';

(async () => {
    const all = await vlogAll(testFile);
    console.log(JSON.stringify(all, null, '  '));
})();