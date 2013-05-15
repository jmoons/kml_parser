require 'date'
require 'csv'

class Activity
    DISTANCE_MATCH_PATTERN  = /(^\d*.\d* km) \((\d*.\d* mi)\)/
    SPEED_MATCH_PATTERN     = /(^\d*.\d* km\/h) \((\d*.\d* mi\/h)\)/

    attr_reader :name, :date, :type, :activity_distance, :time, :activity_speed, :activity_pace

    def initialize(activity_from_kml)
        @name =                 activity_from_kml[:name]
        @date =                 DateTime.strptime(activity_from_kml[:date], "%m/%d/%Y %l:%M")
        @type =                 activity_from_kml[:type]
        @activity_distance =    parse_activity_distance(activity_from_kml)
        @time =                 activity_from_kml[:time]
        @activity_speed =       parse_activity_speed(activity_from_kml)
        @activity_pace =        calculate_activity_pace

    end

    private

    def parse_activity_distance(activity_from_kml)
        {
            :distance_in_kilometers => DISTANCE_MATCH_PATTERN.match(activity_from_kml[:distance])[1].to_f,
            :distance_in_miles      => DISTANCE_MATCH_PATTERN.match(activity_from_kml[:distance])[2].to_f
        }
    end

    def parse_activity_speed(activity_from_kml)
        {
            :speed_in_kilometers_per_hour   => SPEED_MATCH_PATTERN.match(activity_from_kml[:average_speed])[1].to_f,
            :speed_in_miles_per_hour        => SPEED_MATCH_PATTERN.match(activity_from_kml[:average_speed])[2].to_f
        }
    end

    def calculate_activity_pace
        {
            :pace_in_kilometers_per_minute  => ((1 / @activity_speed[:speed_in_kilometers_per_hour]) * 60),
            :pace_in_miles_per_minute       => ((1 / @activity_speed[:speed_in_miles_per_hour]) * 60)
        }
    end
end

class ActivitiesProcessor

    def initialize(activities)
        @activities = activities
    end

    def output_csv
        summary_data = [
                            "Total Activities",
                            "Total Miles",
                            "# of walks",
                            "Miles Walked",
                            "Walking Speed (MPH)",
                            "Walking Pace (Minutes/Mile)",
                            "# of runs",
                            "Miles Ran",
                            "Running Speed (MPH)",
                            "Running Pace (Minutes/Mile)"
                        ]

        activity_header =   [
                                "Date",
                                "Name",
                                "Type",
                                "Distance (m)",
                                "Time",
                                "Speed (mi/h)",
                                "Pace (min/mi)"
                            ]

        #individual activities
        CSV.open("output.csv", "wb") do |csv|
            csv << summary_data
            csv << [
                        sum_item(:activities),
                        sum_item(:activity_miles),
                        sum_item(:walks),
                        sum_item(:miles_walked),
                        average_item(:walking_speed),
                        average_item(:walking_pace),
                        sum_item(:runs),
                        sum_item(:miles_ran),
                        average_item(:running_speed),
                        average_item(:running_pace)
                    ]
            csv << activity_header
            @activities.each do |activity|
                csv <<  [
                            activity.date.strftime("%m/%d/%Y"),
                            activity.name,
                            activity.type,
                            activity.activity_distance[:distance_in_miles],
                            activity.time,
                            activity.activity_speed[:speed_in_miles_per_hour],
                            activity.activity_pace[:pace_in_miles_per_minute]
                        ]
            end
        end
    end

    private

    def sum_item(item)
        sum = 0
        case item
        when :activities
            sum = @activities.length
        when :activity_miles
            @activities.each{|activity| sum += activity.activity_distance[:distance_in_miles]}
        when :runs
            @activities.each{|activity| sum += 1 if activity.type == "running"}
        when :miles_ran
            @activities.each{|activity| sum += activity.activity_distance[:distance_in_miles] if activity.type == "running"}
        when :walks
            @activities.each{|activity| sum += 1 if activity.type == "walking"}
        when :miles_walked
            @activities.each{|activity| sum += activity.activity_distance[:distance_in_miles] if activity.type == "walking"}
        end
        return sum
    end

    def average_item(item)
        sum     = 0
        count   = 0
        case item
        when :walking_speed
            @activities.each do |activity|
                if activity.type == "walking"
                    sum += activity.activity_speed[:speed_in_miles_per_hour]
                    count += 1
                end
            end

        when :walking_pace
            @activities.each do |activity|
                if activity.type == "walking"
                    sum += activity.activity_pace[:pace_in_miles_per_minute]
                    count += 1
                end
            end

        when :running_speed
            @activities.each do |activity|
                if activity.type == "running"
                    sum += activity.activity_speed[:speed_in_miles_per_hour]
                    count += 1
                end
            end

        when :running_pace
            @activities.each do |activity|
                if activity.type == "running"
                    sum += activity.activity_pace[:pace_in_miles_per_minute]
                    count += 1
                end
            end
        end

        sum / count
    end
    
end

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
# What the data will look like coming out of the KML file
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

activities =            []
normalized_activity =   nil

Dir.glob(ARGV[0].dup + "/*.kml").each do |file|
    raw_activity = {}
    File.open(file) do |kml_file|
        ACTIVITY_PARAMETERS.each do |activity_name, activity_match|
            kml_file.find do |line|
                raw_activity[activity_name] = line.gsub(activity_match, "").strip if line =~ activity_match
            end
        end
        normalized_activity = Activity.new(raw_activity)
    end
    activities << normalized_activity
end

ActivitiesProcessor.new(activities).output_csv
