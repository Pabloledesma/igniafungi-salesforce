public class RecalcularEficienciaScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new RecalcularEficienciaBatch(), 200);
    }
}
