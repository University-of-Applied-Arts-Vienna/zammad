# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Create dialog for an admin folder. The target model is implicit (it depends on
#   which admin page opened the dialog), so it is not shown as a form field but
#   injected as a hidden value just before the form is submitted.
class App.AdminFolderNew extends App.ControllerGenericNew
  onSubmit: (e) ->
    if @item?.target_model
      form = $(e.target).closest('form')
      if !form.find('input[name="target_model"]').length
        form.append($('<input>', { type: 'hidden', name: 'target_model', value: @item.target_model }))
    super

# Reusable folder management for an admin index page (App.ControllerSubContent).
#   It extends the generic index config with folder grouping and a "New Folder"
#   button, and provides the create/edit/delete folder dialogs. One instance is
#   created per admin page, scoped to its target model (e.g. 'Trigger').
class App.AdminFolderMenu
  constructor: (options = {}) ->
    @targetModel = options.targetModel
    @container   = options.container
    @onChange    = options.onChange

    # The "New Folder" button is re-rendered with the list, so bind it via event
    #   delegation on the stable container element.
    if @container
      @container.off('click.adminFolder', '[data-type=new-folder]')
      @container.on('click.adminFolder', '[data-type=new-folder]', @newFolder)

  # Extend a generic index config with folder grouping + a "New Folder" button.
  decorateConfig: (config) =>
    config.groupBy            = 'admin_folder'
    config.groupByActions     = @groupByActions()
    config.groupByCollapsible = true
    config.pageData          ||= {}
    config.pageData.buttons ||= []
    config.pageData.buttons.unshift({ name: __('New Folder'), 'data-type': 'new-folder', class: 'btn--secondary' })
    config

  groupByActions: =>
    [
      { name: 'edit-folder',   title: __('Edit folder'),   icon: 'pen',   class: 'js-edit-folder',   callback: @editFolder }
      { name: 'delete-folder', title: __('Delete folder'), icon: 'trash', class: 'js-delete-folder', callback: @deleteFolder }
    ]

  # Preload all folders (full assets), then run the callback (initial render).
  preload: (callback) =>
    App.AdminFolder.fetchFull(
      (-> callback?())
      clear: true
    )

  newFolder: (e) =>
    e?.preventDefault()
    new App.AdminFolderNew(
      genericObject: 'AdminFolder'
      item:          { target_model: @targetModel }
      pageData:      { object: __('Folder') }
      container:     @container
      callback:      @reload
    )

  editFolder: (id, e) =>
    e?.preventDefault()
    new App.ControllerGenericEdit(
      id:            id
      genericObject: 'AdminFolder'
      pageData:      { object: __('Folder') }
      container:     @container
      callback:      @reload
    )

  deleteFolder: (id, e) =>
    e?.preventDefault()
    new App.ControllerGenericDestroyConfirm(
      item:      App.AdminFolder.find(id)
      container: @container
      callback:  @reload
    )

  # Refresh the cached folders and re-render the list after a folder was created,
  #   changed or deleted.
  reload: =>
    App.AdminFolder.fetchFull(
      (=> @onChange?())
      clear: true
    )
