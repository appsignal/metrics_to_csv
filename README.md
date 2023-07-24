# AppSignal metrics to CSV

Uses the AppSignal API to generate CSV files. To install:

```
bundle install
```

Get your personal API token from https://appsignal.com/users/edit

Generate CSV like so:

```
TOKEN=<token> bundle exec ruby export_csv.rb <app-id> <query-name> 2023-07-01 2023-07-08
```

You specify an app id, query name, start date and end date. The query
name refers to query files that can be placed in the `queries` directory.
CSV files will be generated in the `output` directory.

This tool supports exporting counters and gauges at the moment.
