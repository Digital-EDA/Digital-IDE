const assert = require('node:assert/strict');
const { test } = require('node:test');
const { createNetlistHandshake } = require('../out/netlist/handshake');

const message = (type, detail) => ({ protocolVersion: 2, sessionId: 'session', type, message: detail });

test('a started renderer can take longer than the frontend startup timeout', async t => {
    t.mock.timers.enable({ apis: ['setTimeout'] });
    const progress = [];
    const handshake = createNetlistHandshake('session', stage => progress.push(stage));
    let ready = false;
    const observed = handshake.ready.then(() => { ready = true; });
    handshake.receive(message('netlist.started'));
    t.mock.timers.tick(31_000);
    handshake.receive(message('netlist.progress', 'route-legalization'));
    await Promise.resolve();
    assert.equal(ready, false, 'startup or progress must not masquerade as a rendered graph');
    handshake.receive(message('netlist.ready'));
    await observed;
    assert.equal(ready, true);
    assert.deepEqual(progress, ['route-legalization']);
});

test('messages from another session cannot suppress startup failure', async t => {
    t.mock.timers.enable({ apis: ['setTimeout'] });
    const handshake = createNetlistHandshake('session', () => {});
    const rejected = assert.rejects(handshake.ready, /frontend did not start within 30s/);
    handshake.receive({ ...message('netlist.started'), sessionId: 'other' });
    handshake.receive({ ...message('netlist.ready'), protocolVersion: 1 });
    t.mock.timers.tick(30_000);
    await rejected;
});

test('repeated startup and progress cannot extend rendering indefinitely', async t => {
    t.mock.timers.enable({ apis: ['setTimeout'] });
    const handshake = createNetlistHandshake('session', () => {});
    const rejected = assert.rejects(handshake.ready, /exceeded 180s.*route-legalization/);
    handshake.receive(message('netlist.started'));
    t.mock.timers.tick(170_000);
    handshake.receive(message('netlist.started'));
    handshake.receive(message('netlist.progress', 'route-legalization'));
    t.mock.timers.tick(10_000);
    await rejected;
});

test('frontend failures and closing the panel reject immediately', async t => {
    t.mock.timers.enable({ apis: ['setTimeout'] });
    for (const started of [false, true]) {
        const handshake = createNetlistHandshake('session', () => {});
        const rejected = assert.rejects(handshake.ready, /WASM unavailable/);
        if (started) handshake.receive(message('netlist.started'));
        handshake.receive(message('netlist.error', 'WASM unavailable'));
        await rejected;
    }
    const closed = createNetlistHandshake('session', () => {});
    const rejected = assert.rejects(closed.ready, /closed/);
    closed.cancel(new Error('closed'));
    await rejected;
    t.mock.timers.tick(200_000);
});
