def tag_header(key)
  key["tags"].sort_by do |tag|
    tag["key"]
  end.map do |tag|
    "#{tag["key"]}:#{tag["value"]}"
  end.join("-")
end

def metric_key(key)
  "#{key["digest"]};#{key["fields"].first.downcase}"
end
