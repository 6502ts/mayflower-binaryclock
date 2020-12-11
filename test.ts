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
            .writeMemoryAt('editMode', 0)
            .runUntil(() => runner.hasReachedLabel('ClockIncrementDone'));

        assert.strictEqual(runner.readMemoryAt('hours'), 0);
        assert.strictEqual(runner.readMemoryAt('minutes'), 0);
        assert.strictEqual(runner.readMemoryAt('seconds'), 0);
        assert.strictEqual(runner.readMemoryAt('frames'), 0);
    });

    suite('extract lower nibble from BCD', () =>
        [
            [0x90, 0],
            [0x81, 1],
            [0x72, 4],
            [0x63, 5],
            [0x54, 16],
            [0x45, 17],
            [0x36, 20],
            [0x27, 21],
            [0x18, 64],
            [0x09, 65],
        ].forEach(([input, expectation]) =>
            test(`0x${input.toString(16).padStart(2, '0')} -> 0b${expectation.toString(2).padStart(8, '0')}`, () => {
                runner
                    .boot()
                    .cld()
                    .jumpTo('ExtractLowerNibble')
                    .modifyCpuState(() => ({ a: input }))
                    .runToRts();

                assert.strictEqual(runner.getCpuState().a, expectation);
            })
        )
    );

    suite('extract higher nibble from BCD', () =>
        [
            [0x09, 0],
            [0x18, 1],
            [0x27, 4],
            [0x36, 5],
            [0x45, 16],
            [0x54, 17],
            [0x63, 20],
            [0x72, 21],
            [0x81, 64],
            [0x90, 65],
        ].forEach(([input, expectation]) =>
            test(`0x${input.toString(16).padStart(2, '0')} -> 0b${expectation.toString(2).padStart(8, '0')}`, () => {
                runner
                    .boot()
                    .cld()
                    .jumpTo('ExtractHigherNibble')
                    .modifyCpuState(() => ({ a: input }))
                    .runToRts();

                assert.strictEqual(runner.getCpuState().a, expectation);
            })
        )
    );

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

    test('pressing fire toggles edit mode', () => {
        runner.runTo('OverscanLogicStart');

        runner.getBoard().getJoystick0().getFire().toggle(true);
        runner.runTo('OverscanLogicStart');
        assert.strictEqual(runner.readMemoryAt('editMode'), 1);

        runner.getBoard().getJoystick0().getFire().toggle(false);
        runner.runTo('OverscanLogicStart');
        assert.strictEqual(runner.readMemoryAt('editMode'), 1);

        runner.getBoard().getJoystick0().getFire().toggle(true);
        runner.runTo('OverscanLogicStart');
        assert.strictEqual(runner.readMemoryAt('editMode'), 0);

        runner.getBoard().getJoystick0().getFire().toggle(false);
        runner.runTo('OverscanLogicStart');
        assert.strictEqual(runner.readMemoryAt('editMode'), 0);
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
