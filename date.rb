dates = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun','Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
STDIN.each_line do |line|
  matches = line.match(/(\d+)\-(\d+)\-(\d+)/)
  if matches
    month_index = matches[2].to_i - 1
    month = dates[month_index]
    line.sub! /(\d+)\-(\d+)\-(\d+)/, "#{matches[3]}/#{month}/#{matches[1]}"
  end
  puts line
end
