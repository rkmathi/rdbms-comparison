#!/usr/bin/env ruby

require 'fileutils'

TIMES=10
DATA_ROW=100_000
RAND_MAX=1_000_000

def rm
  rand(RAND_MAX)
end

FileUtils.rm(ARGV[0], force: true)

(0...TIMES).each do |t|
  File.open(ARGV[0], "a") do |f|
    f.puts "INSERT INTO comp_table (id, i_x, i_y, i_z, c_x, c_y, c_z) VALUES"
    (1 + (t * DATA_ROW)...DATA_ROW + (t * DATA_ROW)).each do |i|
      f.puts "(#{i}, #{rm}, #{rm}, #{rm}, 'hoge#{rm}', 'fuga#{rm}', 'piyo#{rm}'),"
    end
    f.puts "(#{DATA_ROW + (t * DATA_ROW)}, #{rm}, #{rm}, #{rm}, 'hoge#{rm}', 'fuga#{rm}', 'piyo#{rm}');"
  end
end
