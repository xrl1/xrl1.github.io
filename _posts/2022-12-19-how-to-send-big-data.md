---
title: 'Big data for Dummy Developers - Step Into Foreign Territory'
date: '2022-12-18T00:23:21+02:00'
categories: [Big Data]
tags: ['Big Data', 'dummies', 'Tabular', 'Partitioning', 'Consistency', 'Veracity', 'json', five V', 'developer']
---
So it happens that in about the past year and a bit, I repositioned to a Big Data Engineer role in my company without any prior knowledge.  
I had been writing data pipelines - primarily [Spark](https://spark.apache.org/docs/latest/) Applications in Scala, deployed over k8s infrastructure.

After dealing with those scary words and some others (Iceberg, Data lake, parquet, Kafka, Helm charts, and more), I can say I have learned a lot, and then I realized something - it's not just another flavor of backend engineering - but a whole big thing.  

Lately, I went back to my natural habitat - developing cyber-security solutions in a [system environment](https://en.wikipedia.org/wiki/Systems_programming) in c++.  
And then, my previous realization became even deeper - data is everywhere, and basic knowledge in the field can become handy for any modern software solution in every field.  

### Why data is important?
We live in an age where in order to prove something - we need data to back us up. If we want to make a business decision, we need those numbers, dashboards, and graphs.  
An app developer can claim that he feels the app's performance is too slow - therefore, improving performance should be the most urgent task to do next. But maybe the app metrics will show it is still below the agreed thresholds, but nevertheless, it crashes once for every 3 instances, which could be revealed if telemetry has been sent.  
Simply put - in order to plan our software better, make more confident decisions, and just track what happens within our app, we need to become data-driven.  

While adapting to the new team, the engineering environment, the common jargon, and the technology stack, I couldn't find any decent Big-Data for Dummy developers TL;DR. So if you are ever going to collect and send custom data in your app, here are a couple of concepts to help you step into this foreign territory.  

### The dummiest example
Let's say our app scans files, and we want to send a JSON containing information about the files scanned, such as file format, file size, and scan duration.  
You decide to send the following JSON:
```json
{
	"timestamp": "Fri Dec 16 22:42:50 IST 2022",
	"PDF version 1.4": [
		{
			"file size": "135KB",
			"scan duration": 531000
		},
		{
			"file size": 43105,
			"scan duration": 0.81
		},
		// ...
	],
	// ...
}
```
Each JSON has a timestamp and an array of file size and scan duration dictionaries for each file format. Because the scan time should differ across file types, and you support only a small set of file types, you separate the arrays both logically and to send less data.

Let's explore key Big Data concepts through mistakes in the design above

## Key concepts

### Tabular format
❌  ***Problem*** -  file format is a dynamic key and causes nesting.  
Doesn't matter what data we are about to send or which backend services will process and ingest it, strive to format the data as a table - every piece of information should have its own column with the same name.  

We should think about how the data will be read - usually, it is by SQL or SQL-like querying (it's true for both good old SQL databases as for new NoSQL Big Data solutions).  
In key-value formats, logically keys become columns, and therefore the keys should be constant and not based on the data we collect.  

In the case we send JSONs like this, and the backend ingestion isn't in our control (different team or 3rd party solution), we can find ourselves with the following table:

| Timestamp      | PDF version 1.4 | PDF version 1.7 |
| ----------- | -------- | ------- |
| Fri Dec 16 22:42:50 IST 2022      | [{"file_size" : ...}] | null |
| Fri Dec 16 22:42:52 IST 2022   | null        | [{"file_size" : ...}] |

Almost each data query will require some JSON parsing that can slow down the query duration significantly, the columns can grow without a limit, there will be a lot of null fields, and querying a group of file formats will be a complex task (no LIKE statement for column names).

### Partitioning 
You might know what partitioning is from regular SQL databases: it is an efficient method to split the data according to a specific column we often filter by.  
If we expect to see a daily report on a summary of specific data from our app, the partition column will be a new "day" column which can be derived from the timestamp.  
In NoSQL or Big-Data solutions, the data is usually stored in files on the disk (or cloud storage) in special formats such as parquet, ORC, and others.  
To make it easy to partition the data files, the solution is very neat - each partition will be a folder! A new folder will be created for each new day, and when we execute our day-specific query, only the files from that folder will be processed. 🤯

```
scans.db/
├── day=2023-01-01
│   ├── part1.parquet
│   ├── part2.parquet
│   ├── part3.parquet
│   └── part4.parquet
├── day=2023-01-02
│   ├── part1.parquet
│   ├── part2.parquet
│   └── part3.parquet
└── day=2023-01-03
    ├── part1.parquet
    └── part2.parquet
```
✅  ***Improvement***: Save the timestamp in an easier format to parse and extract the day easier, such as **YYYY-MM-DD hh:mm:ss**.  
But you can, and sometimes should, partition by more than one column.  
In our example, there will be times when we will want to query and make observations about one specific file type only, hence we should partition by it.  
 ✅  ***Improvement***: Because we want to know about the file type without filtering a specific version, we can even improve our end query by sending the version and other data in a different field, and the file type field will hold "PDF" or "DOC" only. This way, we can be more confident that we will hit our partition without using LIKE statements as was needed before.  

### Consistency 
❌  ***Problems*** -  file size values have different types, and scan duration values have different units.  
We want to normalize and keep our data consistent from the sending point - handling it later in the ingestion or during the query can cause mistakes and confusion.  
 ✅  ***Decision breaker***: If it's not essential for the app, prefer using the smallest unit when possible - microseconds instead of seconds as scan duration, and bytes instead of kilobytes for file size. Some reasons are that floating points can cause arithmetic mistakes, and integers will take less space than floats if you use a protocol such as protobuf.  

### **Veracity** - or send more, not less
This one I actually stole from [Big Data five V's](https://www.google.com/search?q=Big%20data%20v%27s), and I refer to an aspect of this concept that can be summarized by a sentence I heard from a co-worker:  
> "I won't send this string because I can later on correlate it from another data source, and in the worst case, I'll manage without this info".   
 
Sometimes it's good to leave out data you don't need. Still, lots of times, we can be very sorry that after all this hard work to create a whole data pipeline, we end up without all the information we want because we tried to save a string or two, especially if we are below pre-defined size limits.  
We should add any useful data we can for further analysis and diagnosis. We can also include in our scan telemetry information like app version and Git hash of the deployed app, so we can identify bugs and track that they are solved in newer versions.  
Other information we can later use is the unique id of the app, the name, and the hash of the file - so in case we find anomalies in the scanning time, we can later contact the client and ask to get the file for bug reproduction.

Let's create a new JSON according to the suggested changes so far:

```json
{
	"timestamp": "2022-16-12 22:42:50",
	"git hash": "f1da229780e39ff6511c0fc227744b2817d122f4",
	"version": "5.1.2.2",
	"file type": "PDF",
	"file size": 924850,
	"scan duration": 445000,
	"uid": "67a8eb1f-b838-4cf7-9f3e-4658f909ca3b",
	"file hash": "f8c3f233bc8e7f64c3a237f7c877323c16916919",
	"file location": "/home/lior/big_data_for_dummy_developers.pdf",
}
```

That's it for this blog post, and part 2 is coming with more big data at a glance.  
Hope you learned something new!