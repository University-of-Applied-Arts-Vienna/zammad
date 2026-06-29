class App.AdminFolder extends App.Model
  @configure 'AdminFolder', 'name', 'parent_id', 'target_model', 'prio', 'active'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/admin_folders'

  # Only offer folders of the same object type as parent (admin folder trees are
  #   scoped per target model). The current target model is read from the form
  #   params, which are seeded with it when the folder dialog is opened.
  @filterByTargetModel: (collection, type, params) ->
    return collection if type isnt 'collection'
    return collection if !params or !params.target_model

    _.filter(collection, (item) -> item?.target_model is params.target_model)

  # Build a relation-select filter that keeps only the folders of a fixed target
  #   model. Used by the foldered admin objects (Trigger, TextModule, ...) whose
  #   form has no target_model field to derive the scope from.
  @filterForTargetModel: (targetModel) ->
    (collection, type) ->
      return collection if type isnt 'collection'

      _.filter(collection, (item) -> item?.target_model is targetModel)

  @configure_attributes = [
    { name: 'name',          display: __('Name'),          tag: 'input',   type: 'text', translate: true, limit: 100, 'null': false },
    { name: 'parent_id',     display: __('Parent folder'), tag: 'select',  multiple: false, null: true, relation: 'AdminFolder', nulloption: true, filter: @filterByTargetModel },
    { name: 'active',        display: __('Active'),        tag: 'active',  default: true },
    { name: 'prio',          display: __('Position'),      tag: 'integer', type: 'number', limit: 100, null: true },
    { name: 'created_by_id', display: __('Created by'),     relation: 'User', readonly: 1 },
    { name: 'created_at',    display: __('Created'),        tag: 'datetime', readonly: 1 },
    { name: 'updated_by_id', display: __('Updated by'),     relation: 'User', readonly: 1 },
    { name: 'updated_at',    display: __('Updated'),        tag: 'datetime', readonly: 1 },
  ]
  @configure_delete = true

  # Returns the full folder path including all parents, e.g. "Sales / Escalations".
  displayName: ->
    names    = [@name]
    parentId = @parent_id
    guard    = 0
    while parentId && guard < 20
      guard += 1
      break if !App.AdminFolder.exists(parentId)
      parent = App.AdminFolder.find(parentId)
      names.unshift(parent.name)
      parentId = parent.parent_id
    names.join(' / ')
