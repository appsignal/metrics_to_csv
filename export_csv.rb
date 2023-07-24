require "debug"
require "csv"
require "fileutils"
require "json"
require 'rest-client'
require 'active_support'
require 'active_support/core_ext'

# Get all required information
app_id = ARGV[0] or raise "Specify app id as the first argument"
query_name = ARGV[1] or raise "Specify query name as second argument"
start_date = ARGV[2] or raise "Specify start date as third argument"
end_date = ARGV[3] or raise "Specify end date as fourth argument"

query = JSON.parse(File.read("queries/#{query_name}.json"))
start_date = Date.parse(start_date)
end_date = Date.parse(end_date)

puts "Exporting CSV for #{app_id} with query #{query_name} from #{start_date} to #{end_date}"

token = ENV["TOKEN"] or raise "No TOKEN env var set"

# Endpoint and query to fetch metrics
ENDPOINT = "https://appsignal.com/graphql"
QUERY = <<-QUERY
query MetricTimeseriesQuery(
  $appId: String!
  $start: DateTime
  $end: DateTime
  $timeframe: TimeframeEnum
  $query: [MetricTimeseries]
) {
  app(id: $appId) {
    id
    metrics {
      timeseries(
        start: $start
        end: $end
        timeframe: $timeframe
        query: $query
      ) {
        start
        end
        resolution
        keys {
          name
          digest
          fields
          tags {
            key
            value
          }
        }
        points {
          timestamp
          values {
            key
            value
          }
        }
      }
    }
  }
}
QUERY

# Variables for the graphql query based
# off the various inputs
variables = {
  "appId" => app_id,
  "start" => start_date.beginning_of_day,
  "end" => end_date.end_of_day,
  "query" => query
}.to_json

# Execute the query
result = begin
  RestClient.post(
  "#{ENDPOINT}?token=#{token}",
  {:query => QUERY, :variables => variables}
)
rescue => e
  raise e.response.body.inspect
end
response = JSON.parse(result)

# Get to the metrics part
metrics = response["data"]["app"]["metrics"]
keys = metrics["timeseries"]["keys"]
points = metrics["timeseries"]["points"]

keys.each do |key|
  puts key
end

points.each do |point|
  puts point
end

# Generate CSV
FileUtils.mkdir_p "output"
filename = "output/#{query_name}-#{start_date}-#{end_date}.csv"

CSV.open(filename, "wb") do |csv|
  # Add header row with the fields
  header = ["timestamp"]
  keys.each do |key|
    header << key["tags"].map do |tag|
      "#{tag["key"]}:#{tag["value"]}"
    end.join("-")
  end
  csv << header

  # Add rows with timestamps and points
  points.each do |point|
    row = [point["timestamp"]]

    # Lookup the point based on the key
    # and add to the row
    keys.each do |key|
      point["values"].select do |value|
        value["key"] == "#{key["digest"]};#{key["fields"].first.downcase}"
      end.each do |value|
        row << value["value"]
      end
    end

    csv << row
  end
end

puts "Wrote CSV to #{filename}"
