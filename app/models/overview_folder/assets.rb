# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class OverviewFolder
  module Assets
    extend ActiveSupport::Concern

    # Ship the folder together with its whole ancestor chain, so the client can
    #   render the full folder path (e.g. "Team A / Open").
    def assets(data = {})
      app_model = OverviewFolder.to_app_model
      already_included = data.dig(app_model, id).present?

      data = super

      return data if already_included

      if parent_id && (parent = OverviewFolder.lookup(id: parent_id))
        data = parent.assets(data)
      end

      data
    end
  end
end
