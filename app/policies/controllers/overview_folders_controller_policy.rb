# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Controllers::OverviewFoldersControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.overview')
end
