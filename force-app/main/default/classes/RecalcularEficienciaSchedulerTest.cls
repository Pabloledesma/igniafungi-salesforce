@IsTest
private class RecalcularEficienciaSchedulerTest {

    private static final String CRON_2AM = '0 0 2 * * ?';

    @IsTest
    static void schedule_registersCronTriggerCorrectly() {
        Test.startTest();
        String jobId = System.schedule(
            'RecalcularEficiencia_Test',
            CRON_2AM,
            new RecalcularEficienciaScheduler()
        );
        Test.stopTest();

        CronTrigger ct = [SELECT CronExpression, State FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(CRON_2AM, ct.CronExpression);
        System.assertEquals('WAITING', ct.State);
    }

    @IsTest
    static void schedule_multipleJobsCanBeRegistered() {
        Test.startTest();
        String jobA = System.schedule('RecalcularEficiencia_JobA', '0 0 2 * * ?', new RecalcularEficienciaScheduler());
        String jobB = System.schedule('RecalcularEficiencia_JobB', '0 0 3 * * ?', new RecalcularEficienciaScheduler());
        Test.stopTest();

        List<CronTrigger> jobs = [SELECT Id FROM CronTrigger WHERE Id IN :new Set<Id>{ jobA, jobB }];
        System.assertEquals(2, jobs.size());
    }
}
