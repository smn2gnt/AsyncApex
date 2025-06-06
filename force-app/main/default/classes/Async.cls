public with sharing class Async {
    public Interface Batch {
        String start(); // MODIFIED: Was Iterable<sObject>
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