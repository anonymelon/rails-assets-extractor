require "rubygems/indexer"
require './models/build/converter'
require './models/component'

namespace :local do
  desc 'convert a local bower repo to gem file'
  task :convert do
    result = Build::Converter.local_build('/Users/Jeremy/workspace/test/ui-grid-master')
    result
  end
end
