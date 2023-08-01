# Custom Async Framework for Salesforce Apex(Experimental)

Welcome to the Custom Async Framework for Salesforce Apex! This project provides an alternative to Salesforce's built-in Queueable and Batch Apex classes, leveraging Platform Cache and Platform Events to achieve asynchronous processing in Salesforce org.

# Table of Contents

- [Custom Async Framework for Salesforce Apex(Experimental)](#custom-async-framework-for-salesforce-apexexperimental)
- [Table of Contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Features](#features)
  - [Installation](#installation)
  - [Usage](#usage)
    - [Queue Type Job](#queue-type-job)
    - [Batch Type Job](#batch-type-job)
  - [Interfaces](#interfaces)
    - [Batch Interface](#batch-interface)
    - [Queue Interface](#queue-interface)
    - [Stateful Interface](#stateful-interface)
  - [Components](#components)
    - [Platform Cache Setup](#platform-cache-setup)
    - [Platform Event Setup](#platform-event-setup)
    - [EnqueueJobs Class](#enqueuejobs-class)
    - [AsyncJobTriggerHandler Class](#asyncjobtriggerhandler-class)
  - [Limitations](#limitations)
  - [Contributing](#contributing)
  - [License](#license)

## Introduction

Salesforce provides powerful tools for asynchronous processing like Queueable and Batch Apex. However, there are scenarios where additional control and customization are required, and this is where the Custom Async Framework comes into play. The framework utilizes Platform Cache to store class instances and Platform Events to execute actions in a sequence, making it a reliable and efficient solution for  asynchronous processing needs.

## Features

- Alternative to Queueable and Batch Apex.
- Utilizes Salesforce Platform Cache for storing class instances, reducing the overhead of object initialization.
- Leverages Platform Events as an event bus for executing actions in a sequence.
- Easy-to-use and intuitive API for developers.

## Installation

To use the Custom Async Framework in your Salesforce org, follow these steps:

1. Clone the repository to your local machine or download the latest release.
2. Deploy the components to your Salesforce org using the Salesforce CLI or any other deployment tool.

## Usage

Using the Custom Async Framework is straightforward. Here's a quick guide:

### Queue Type Job

To utilize the Custom Async Framework for a Queue type job, follow this example:

1. Create a Queue class that implements the `Async.Queue` interface:

```apex
public with sharing class MyQueueJob implements Async.Queue {
    private String message;

    public MyQueueJob(String message) {
        this.message = message;
    }

    public void execute() {
        // Perform your asynchronous operations here...
        System.debug('Executing Queue Job with message: ' + message);
        // Add custom logic as needed...
    }
}
```

2. Enqueue the job using the `EnqueueJobs` class:

```apex
String myMessage = 'Hello, from the Custom Async Framework!';
Async.Queue myQueueJob = new MyQueueJob(myMessage);
EnqueueJobs.Enqueue(myQueueJob);
```

### Batch Type Job

1. Create a Batch class that implements the `Async.Batch` interface:


```apex
public without sharing class MyBatchJob implements Async.Batch, Async.Stateful {
    Integer recordsProcessed = 0;

    public Iterable<Sobject> start() {
        return new IterableSobject(
            'SELECT Id, Name FROM MyCustomObject__c WHERE Status__c = \'Pending\' LIMIT 200'
        );
    }

    public void execute(List<SObject> scope) {
        // Process each batch of records
        for (SObject record : scope) {
            // Add your batch processing logic here...
            record.put('Status__c', 'Processed');
            recordsProcessed++;
        }
        update scope;
    }

    public void finish() {
        System.debug(recordsProcessed + ' records processed. Batch job complete!');
    }
}
```
2. Enqueue the Batch job

```apex
String jobId = EnqueueJobs.Batch(MyBatchJob);
```


## Interfaces

The Custom Async Framework utilizes the following interfaces for defining asynchronous jobs:

### Batch Interface

The `Batch` interface defines the structure of a Batch Apex job.

```apex
public Interface Batch {
    Iterable<sObject> start();
    void execute(List<SObject> scope);
    void finish();
}
```

### Queue Interface

The `Queue` interface defines the structure of a Queueable job.

```apex
public Interface Queue {
    void execute();
}
```

### Stateful Interface

The `Stateful` interface serves as a marker interface to indicate that a Batch Apex job should maintain its state.

```apex
public Interface Stateful {
    // Marker Interface
}
```

## Components

The Custom Async Framework is composed of several components, each serving a specific purpose. Here are the key components included in this framework:

### Platform Cache Setup

The Platform Cache setup is essential for utilizing the Custom Async Framework effectively. Ensure that you have set up the Platform Cache as described in the package.

### Platform Event Setup

The Platform Event setup is essential for handling asynchronous events in the Custom Async Framework. Ensure that you have set up the Platform Event and the associated trigger as described in the package.

### EnqueueJobs Class

The `EnqueueJobs` class is responsible for enqueuing asynchronous jobs, either Queueable or Batch.


### AsyncJobTriggerHandler Class

The `AsyncJobTriggerHandler` class is responsible for processing Queue and Batch jobs triggered by Platform Events.


## Limitations

While the Custom Async Framework offers an alternative for asynchronous processing in Salesforce Apex, it also has many limitations that developers should be aware of:

1. **No Direct Callouts**: Framework does not support making callouts for obvious reasons.
   
2. **No Querylocator**: Framework does not support using the `Database.getQueryLocator()` method within Batch type jobs. If your use case requires this feature, please be aware that it is not compatible with the framework's current implementation.

3. **Limited Number of Records**: In Batch jobs, the number of records returned by the `start` method should not exceed 100 KB. 
   
4. **Platform Cache Limits**: The usage of Platform Cache is subject to its own limits and allocations in your Salesforce org. Ensure that you monitor the cache usage to avoid reaching the limits.


4. **Governor Limits**: As with any Salesforce Apex code, the Custom Async Framework is subject to governor limits. Ensure that your asynchronous jobs are designed to comply with these limits.

## Contributing

Contributions to the Custom Async Framework are welcome! 

## License

This project is licensed under the [MIT License](LICENSE).

---

