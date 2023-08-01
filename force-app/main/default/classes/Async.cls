public with sharing class Async {
    public Interface Batch {
        Iterable<sObject> start();
        void execute(List<SObject> scope);
        void finish();
    }
    public Interface Queue {
        void execute();
    }
    public Interface Stateful {
        //Marker Interface
    }
}