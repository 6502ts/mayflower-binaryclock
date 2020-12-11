import assert from 'assert';
import path from 'path';
import VcsRunner from '6502.ts/lib/test/VcsRunner';

suite('binclock', () => {
    let runner: VcsRunner;

    setup(async () => {
        runner = await VcsRunner.fromFile(path.join(__dirname, 'bitclock.asm'));
    });

    test('memory is initialized', () => {
        runner.runUntil(() => runner.hasReachedLabel('InitComplete'));

        for (let i = 0xff; i >= 0x80; i--) {
            assert.strictEqual(runner.readMemory(i), 0, `located at 0x${i.toString(16).padStart(4, '0')}`);
        }
    });

    test('handles day-change properly (via mainloop)', () => {
        runner
            .runUntil(() => runner.hasReachedLabel('AdvanceClock'))
            .writeMemoryAt('hours', 0x23)
            .writeMemoryAt('minutes', 0x59)
            .writeMemoryAt('seconds', 0x59);

        for (let i = 0; i < 50; i++) {
            runner.runUntil(() => runner.hasReachedLabel('AdvanceClock'));
        }

        assert.strictEqual(runner.readMemoryAt('hours'), 0);
        assert.strictEqual(runner.readMemoryAt('minutes'), 0);
        assert.strictEqual(runner.readMemoryAt('seconds'), 0);
    });

    test('handles day-change properly (unit test)', () => {
        runner
            .boot()
            .cld()
            .jumpTo('AdvanceClock')
            .writeMemoryAt('hours', 0x23)
            .writeMemoryAt('minutes', 0x59)
            .writeMemoryAt('seconds', 0x59)
            .writeMemoryAt('frames', 49)
            .writeMemoryAt('editMode', 0x80)
            .runUntil(() => runner.hasReachedLabel('ClockIncrementDone'));

        assert.strictEqual(runner.readMemoryAt('hours'), 0);
        assert.strictEqual(runner.readMemoryAt('minutes'), 0);
        assert.strictEqual(runner.readMemoryAt('seconds'), 0);
        assert.strictEqual(runner.readMemoryAt('frames'), 0);
    });

    test('clock is halted in edit mode', () => {
        runner
            .boot()
            .cld()
            .jumpTo('AdvanceClock')
            .writeMemoryAt('hours', 0x23)
            .writeMemoryAt('minutes', 0x59)
            .writeMemoryAt('seconds', 0x59)
            .writeMemoryAt('frames', 49)
            .writeMemoryAt('editMode', 1)
            .runUntil(() => runner.hasReachedLabel('ClockIncrementDone'));

        assert.strictEqual(runner.readMemoryAt('hours'), 0x23);
        assert.strictEqual(runner.readMemoryAt('minutes'), 0x59);
        assert.strictEqual(runner.readMemoryAt('seconds'), 0x59);
        assert.strictEqual(runner.readMemoryAt('frames'), 49);
    });

    test('pressing fire toggles edit mode bit 7', () => {
        runner.runTo('OverscanLogicStart').writeMemoryAt('editMode', 0x01);

        runner.getBoard().getJoystick0().getFire().toggle(true);
        runner.runTo('OverscanLogicStart');
        assert.strictEqual(runner.readMemoryAt('editMode'), 0x81);

        runner.getBoard().getJoystick0().getFire().toggle(false);
        runner.runTo('OverscanLogicStart');
        assert.strictEqual(runner.readMemoryAt('editMode'), 0x81);

        runner.getBoard().getJoystick0().getFire().toggle(true);
        runner.runTo('OverscanLogicStart');
        assert.strictEqual(runner.readMemoryAt('editMode'), 0x01);

        runner.getBoard().getJoystick0().getFire().toggle(false);
        runner.runTo('OverscanLogicStart');
        assert.strictEqual(runner.readMemoryAt('editMode'), 0x01);
    });

    test('frame size is 312 lines / PAL', () => {
        let cyclesAtFrameStart = -1;

        runner
            .runTo('MainLoop')
            .trapAt('MainLoop', () => {
                if (cyclesAtFrameStart > 0) {
                    assert.strictEqual(runner.getCpuCycles() - cyclesAtFrameStart, 312 * 76);
                }

                cyclesAtFrameStart = runner.getCpuCycles();
            })
            .runTo('MainLoop')
            .runTo('MainLoop');
    });

    test('frame size is 312 lines / PAL with overflow', () => {
        let cyclesAtFrameStart = -1;

        runner
            .runTo('MainLoop')
            .trapAt('MainLoop', () => {
                if (cyclesAtFrameStart > 0) {
                    assert.strictEqual(runner.getCpuCycles() - cyclesAtFrameStart, 312 * 76);
                }

                cyclesAtFrameStart = runner.getCpuCycles();
            })
            .runTo('MainLoop')
            .writeMemoryAt('hours', 0x23)
            .writeMemoryAt('minutes', 0x59)
            .writeMemoryAt('seconds', 0x59)
            .writeMemoryAt('frames', 49)
            .runTo('MainLoop');
    });

    test('it takes 50 frames to count one second', () => {
        let frameNo = 1;

        runner
            .runTo('MainLoop')
            .writeMemoryAt('hours', 0)
            .writeMemoryAt('minutes', 0)
            .writeMemoryAt('seconds', 0)
            .writeMemoryAt('frames', 0)
            .trapAt('MainLoop', () => frameNo++)
            .runUntil(() => runner.readMemoryAt('seconds') === 1, 100 * 312 * 76);

        assert.strictEqual(frameNo, 50);
    });
});
