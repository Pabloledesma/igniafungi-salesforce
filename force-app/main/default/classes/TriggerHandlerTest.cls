@IsTest
private class TriggerHandlerTest {

    // Concrete subclass used only inside tests
    private class MockHandler extends TriggerHandler {
        public Integer beforeInsertCalls = 0;
        protected override void beforeInsert() {
            beforeInsertCalls++;
        }
    }

    // ── Bypass API ────────────────────────────────────────────────────────────

    @IsTest
    static void bypass_marksHandlerAsBypassed() {
        TriggerHandler.bypass('MockHandler');
        System.assert(TriggerHandler.isBypassed('MockHandler'), 'Handler should be bypassed');
    }

    @IsTest
    static void clearBypass_removesHandlerFromBypassList() {
        TriggerHandler.bypass('MockHandler');
        TriggerHandler.clearBypass('MockHandler');
        System.assert(!TriggerHandler.isBypassed('MockHandler'), 'Handler should not be bypassed after clear');
    }

    @IsTest
    static void clearAllBypasses_removesAllHandlers() {
        TriggerHandler.bypass('MockHandler');
        TriggerHandler.bypass('AnotherHandler');
        TriggerHandler.clearAllBypasses();
        System.assert(!TriggerHandler.isBypassed('MockHandler'), 'MockHandler should not be bypassed');
        System.assert(!TriggerHandler.isBypassed('AnotherHandler'), 'AnotherHandler should not be bypassed');
    }

    @IsTest
    static void isBypassed_returnsFalseForUnregisteredHandler() {
        System.assert(!TriggerHandler.isBypassed('NonExistentHandler'));
    }

    // ── run() outside trigger context ─────────────────────────────────────────

    @IsTest
    static void run_doesNothingOutsideTriggerContext() {
        MockHandler handler = new MockHandler();
        // isTriggerExecuting is false here (not in a real trigger)
        handler.run();
        System.assertEquals(0, handler.beforeInsertCalls, 'No handler method should fire outside trigger context');
    }

    @IsTest
    static void run_doesNothingWhenBypassed() {
        MockHandler handler = new MockHandler();
        // Resolve the exact name the framework assigns to this handler
        String resolvedName = String.valueOf(handler).substringBefore(':');
        TriggerHandler.bypass(resolvedName);

        handler.run();

        System.assertEquals(0, handler.beforeInsertCalls, 'Bypassed handler should not fire');
        TriggerHandler.clearBypass(resolvedName);
    }
}
