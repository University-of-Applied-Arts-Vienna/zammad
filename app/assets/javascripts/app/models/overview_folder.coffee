class App.OverviewFolder extends App.Model
  @configure 'OverviewFolder', 'name', 'parent_id', 'prio', 'active'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/overview_folders'
  @configure_attributes = [
    { name: 'name',      display: __('Name'),   tag: 'input',  type: 'text', translate: true, limit: 100, 'null': false },
    { name: 'parent_id', display: __('Parent folder'), tag: 'select', multiple: false, null: true, relation: 'OverviewFolder', nulloption: true },
    { name: 'active',    display: __('Active'), tag: 'active', default: true },
    { name: 'prio',      display: __('Position'), tag: 'integer', type: 'number', limit: 100, null: true },
    { name: 'created_by_id', display: __('Created by'), relation: 'User', readonly: 1 },
    { name: 'created_at',    display: __('Created'),    tag: 'datetime', readonly: 1 },
    { name: 'updated_by_id', display: __('Updated by'), relation: 'User', readonly: 1 },
    { name: 'updated_at',    display: __('Updated'),    tag: 'datetime', readonly: 1 },
  ]
  @configure_delete = true
  @configure_overview = [
    'name',
    'prio',
  ]

  @description = __('''
**Folders** let you group ticket overviews. Folders can be nested and overviews can also stay at the root level.

A folder is only shown to a user if they have access to at least one overview inside it.
''')

  # Returns the full folder path including all parents, e.g. "Team A / Open".
  displayName: ->
    names    = [@name]
    parentId = @parent_id
    guard    = 0
    while parentId && guard < 20
      guard += 1
      break if !App.OverviewFolder.exists(parentId)
      parent = App.OverviewFolder.find(parentId)
      names.unshift(parent.name)
      parentId = parent.parent_id
    names.join(' / ')
