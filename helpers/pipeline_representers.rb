module Representers
  class MaterialRepresenter < Representable::Decorator

    include Representable::JSON

    property :type
    property :attributes do
      property :url
      property :destination
      property :filter
      property :invert_filter
      property :name
      property :auto_update
      property :branch
      property :submodule_folder
      property :shallow_clone
    end

  end


  class PipelineRepresenter < Representable::Decorator

    include Representable::JSON

    property :group
    property :pipeline do
      property :label_template
      property :name
      property :template
      property :enable_pipeline_locking
      collection :parameters
      collection :environment_variables
      collection :materials, decorator: MaterialRepresenter
      property :stages
      property :tracking_tool
      property :timer
    end
end


end
