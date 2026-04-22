public virtual class TriggerHandler {

    private static Set<String> bypassedHandlers = new Set<String>();
    private static Set<String> activeHandlers = new Set<String>();

    private String handlerName;
    @TestVisible
    protected Boolean isTriggerExecuting;

    public TriggerHandler() {
        this.handlerName = getHandlerName();
        this.isTriggerExecuting = Trigger.isExecuting;
    }

    public void run() {
        if (!validateRun()) return;

        activeHandlers.add(handlerName);

        if (Trigger.isBefore) {
            if (Trigger.isInsert)  beforeInsert();
            if (Trigger.isUpdate)  beforeUpdate();
            if (Trigger.isDelete)  beforeDelete();
        } else {
            if (Trigger.isInsert)   afterInsert();
            if (Trigger.isUpdate)   afterUpdate();
            if (Trigger.isDelete)   afterDelete();
            if (Trigger.isUndelete) afterUndelete();
        }

        activeHandlers.remove(handlerName);
    }

    private Boolean validateRun() {
        if (!isTriggerExecuting)                  return false;
        if (bypassedHandlers.contains(handlerName)) return false;
        if (activeHandlers.contains(handlerName))   return false;
        return true;
    }

    private String getHandlerName() {
        return String.valueOf(this).substringBefore(':');
    }

    public static void bypass(String handlerName) {
        bypassedHandlers.add(handlerName);
    }

    public static void clearBypass(String handlerName) {
        bypassedHandlers.remove(handlerName);
    }

    public static Boolean isBypassed(String handlerName) {
        return bypassedHandlers.contains(handlerName);
    }

    public static void clearAllBypasses() {
        bypassedHandlers.clear();
    }

    protected virtual void beforeInsert()   {}
    protected virtual void beforeUpdate()   {}
    protected virtual void beforeDelete()   {}
    protected virtual void afterInsert()    {}
    protected virtual void afterUpdate()    {}
    protected virtual void afterDelete()    {}
    protected virtual void afterUndelete()  {}
}
