MILE_MATCH_PATTERN  = /\d+.\d+ mi/

ACTIVITY_PARAMETERS = {
    :name           => /Name:/i,
    :type           => /Activity type:/i,
    :distance       => /Total distance:/i,
    :time           => /Total time:/i,
    :average_speed  => /Average speed:/i,
    :max_speed      => /Max speed:/i,
    :average_pace   => /Average pace:/i,
    :max_pace       => /Fastest pace:/i,
    :date           => /Recorded:/i
}

activities = []
Dir.glob(ARGV[0].dup + "/*.kml").each do |file|
    activity = {}
    File.open(file) do |kml_file|
        ACTIVITY_PARAMETERS.each do |activity_name, activity_match|
            kml_file.find do |line|
                activity[activity_name] = line.gsub(activity_match, "").strip if line =~ activity_match
            end
        end
    end
    activities << activity
end

total_miles = 0
run_count   = 0
run_miles   = 0
walk_count  = 0
walk_miles  = 0

activities.each do |activity|
    activity_miles = activity[:distance].match(MILE_MATCH_PATTERN).to_s.to_f
    total_miles += activity_miles
    if activity[:type].downcase.eql?("walking")
        walk_count += 1
        walk_miles += activity_miles
    else
        run_count += 1
        run_miles += activity_miles
    end
end
puts "\nTotal Activities: #{activities.length}"
puts "Total Miles: #{total_miles.round(3)}\n\n"
puts "# of Runs: #{run_count}\n"
puts "Run Miles: #{run_miles.round(3)}\n\n"
puts "# of Walks: #{walk_count}\n"
puts "Walk Miles: #{walk_miles.round(3)}\n\n"

# {
#     :name=>"SW Rec Center", 
#     :type=>"walking", 
#     :distance=>"8.41 km (5.2 mi)", 
#     :time=>"1:11:16", 
#     :average_speed=>"7.08 km/h (4.4 mi/h)", 
#     :max_speed=>"12.60 km/h (7.8 mi/h)", 
#     :average_pace=>"8.48 min/km (13.6 min/mi)", 
#     :max_pace=>"4.76 min/km (7.7 min/mi)", 
#     :date=>"3/18/2013 6:56am"
# }
