require 'activerecord'
require './models/build/converter'
require './models/component'

namespace :component do
  desc 'Convert a bower repo to gem'
  task :convert do
    # Remove component to force rebuild
    component, version = Component.get(args[:name], args[:version])
    version.update_attribute(:rebuild, true) if version.present?

    result = Build::Converter.run!(args[:name], args[:version]).inspect
    Build::Converter.index!(true)
    result
  end
end
