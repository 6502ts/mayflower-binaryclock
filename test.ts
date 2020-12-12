import assert from 'assert';
import path from 'path';
import VcsRunner from '6502.ts/lib/test/VcsRunner';
import { readFileSync } from 'fs';

const includes = {
    'bitclock_macros.h': readFileSync('./bitclock_macros.h'),
    'constants.h': readFileSync('./constants.h'),
    'variables.h': readFileSync('./variables.h'),
};

suite('macros', () => {
    function newRunner(source: string): Promise<VcsRunner> {
        return VcsRunner.fromSource(
            `
    processor 6502
    include vcs.h
    include macro.h

    include bitclock_macros.h
    include variables.h

    seg code_main
    org $F000

Start
${source}

    include constants.h

    org $FFFC
    .word Start
    .word Start`,
            { includes }
        );
    }

    test('ASLN shifts left', async () => {
        const runner = (
            await newRunner(`
    ASLN 3
done
        `)
        )
            .modifyCpuState(() => ({ a: 0x01 }))
            .runTo('done');

        assert.strictEqual(runner.getCpuState().a, 0x08);
    });

    test('LSRN shifts right', async () => {
        const runner = (
            await newRunner(`
    LSRN 3
done
        `)
        )
            .modifyCpuState(() => ({ a: 0x80 }))
            .runTo('done');

        assert.strictEqual(runner.getCpuState().a, 0x10);
    });

    suite('LDEXPAND spreads a BCD digit over a full byte and stores the result in A', () => {
        [
            [0x00, 0x00],
            [0x01, 0x01],
            [0x02, 0x04],
            [0x03, 0x05],
            [0x04, 0x10],
            [0x05, 0x11],
            [0x06, 0x14],
            [0x07, 0x15],
            [0x08, 0x40],
            [0x09, 0x41],
        ].forEach(([input, expectation]) =>
            test(`0x${input.toString(16).padStart(2, '0')} -> 0b${expectation
                .toString(2)
                .padStart(8, '0')}`, async () => {
                const runner = (
                    await newRunner(`
    LDEXPAND scratch
done
                `)
                )
                    .writeMemoryAt('scratch', input)
                    .runTo('done');

                assert.strictEqual(runner.getCpuState().a, expectation);
            })
        );
    });
});

suite('binclock', () => {
    let runner: VcsRunner;

    setup(async () => {
        runner = await VcsRunner.fromFile(path.join(__dirname, 'bitclock.asm'), { includes });
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
