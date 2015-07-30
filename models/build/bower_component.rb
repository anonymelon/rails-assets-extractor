require './models/build/gem_component'
require './models/build/paths'

module Build
  class BowerComponent
    attr_reader :cache_dir, :data

    # cache_dir - Build::Path to which component has been installed
    # data - The component's Hash returned by `bower info` or similar
    def initialize(cache_dir, data)
      @cache_dir = Path.new(cache_dir)
      @data = data
    end

    def component_dir
      Path.new(data['canonicalDir'])
    end

    def name
      data['name'].split('/').last
    end

    def license
      data['latest']['license']
    end

    def user
      full_name.split('/')[0]
    end

    def repo
      full_name.split('/')[1]
    end

    def version
      if data['latest']['version']
        data['latest']['version']
      else
        raise BuildError.new(
          "#{full_name} has no versions defined. " +
          "Please create an issue in component's repository."
        )
      end
    end

    def description
      data['latest']['description'] || ""
    end

    def repository
      data['latest']['_source']
    end

    def homepage
      PostRank::URI.normalize(data['latest']['homepage']).to_s
    rescue
      nil
    end

    def dependencies
      data['latest']['dependencies'] || {}
    end

    def main
      if mains = data['latest']['main']
        if mains.kind_of?(Hash)
          mains.values.flatten.compact
        elsif mains.kind_of?(Array)
          mains.flatten.compact
        elsif mains.kind_of?(String)
          [mains]
        end
      end
    end

    def github?
      data['endpoint']['source'].include?('/')
    end

    def full_name
      # source = data['endpoint']['source']
      source = data['name'].split('/').last
      source = source.sub(/#.*$/, '')
      source = source.sub(/\.git$/, '')

      if source.match(/^[^\/]+(\/[^\/]+)?$/)
        source
      elsif source =~ /github\.com\/([^\/]+\/[^\/]+)/
        $1
      else
        raise BuildError.new("#{source} is not valid source for rails-assets")
      end
    end

    def full
      "#{data['endpoint']['source']}##{data['endpoint']['target']}"
    end

    def paths
      Paths.from(component_dir).map(:relative_path_from, component_dir)
    end

    def main_paths
      Paths.new(main).
        map(:expand_path, component_dir).select(:exist?).
        map(:relative_path_from, component_dir)
    end

    def gem
      @gem ||= GemComponent.new(self)
    end

    def needs_build?
      Component.where
    end

    def version_model
      component = Component.find_or_initialize_by(name: gem.short_name)

      component.attributes = {
        bower_name: full_name,
        description: description,
        homepage: homepage
      }

      version = component.versions.string(gem.version).first

      if version.blank?
        version = component.versions.new(string: gem.version)
        version.component = component
      end

      version.attributes = {
        bower_version: self.version,
        dependencies: gem.dependencies
      }

      version
    end
  end
end
