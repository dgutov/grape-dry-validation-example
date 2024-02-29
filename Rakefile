task :environment do
  require './api'
end

desc 'Print out routes'
task :routes => :environment do
  Apples::API.routes.each do |route|
    description = "%-40s..." % route.description[0..39]
    method = "%-7s" % route.options[:method]
    puts "#{description}  #{method}#{route.path}"
  end
end

desc 'Run test'
task :test => :environment do
  system("ruby api_test.rb")
end
