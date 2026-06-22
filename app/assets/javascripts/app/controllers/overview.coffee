# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Overview extends App.ControllerSubContent
  @requiredPermission: 'admin.overview'
  header: __('Overviews')

  events:
    'click [data-type=new-folder]':  'newFolder'
    'click [data-type=bulk-edit]':   'bulkEdit'

  bulkEditLabel: __('Edit selected')

  constructor: ->
    super

    # update group by with current attributes
    for attribute in App.Overview.configure_attributes
      if attribute.name is 'group_by'
        attribute.options = App.Overview.groupByAttributes()

    @genericController = new App.ControllerGenericIndex(
      el: @el
      id: @id
      genericObject: 'Overview'
      defaultSortBy: 'prio'
      groupBy: 'folder'
      groupByActions: [
        {
          name:     'edit-folder'
          title:    __('Edit folder')
          icon:     'pen'
          class:    'js-edit-folder'
          callback: @editFolder
        }
        {
          name:     'delete-folder'
          title:    __('Delete folder')
          icon:     'trash'
          class:    'js-delete-folder'
          callback: @deleteFolder
        }
      ]
      searchBar: true
      searchQuery: @search_query
      pageData:
        home: 'overviews'
        object: __('Overview')
        objects: __('Overviews')
        searchPlaceholder: __('Search for overviews')
        pagerAjax: true
        pagerBaseUrl: '#manage/overviews/'
        pagerSelected: ( @page || 1 )
        pagerPerPage: 50
        navupdate: '#overviews'
        buttons: [
          { name: @bulkEditLabel, 'data-type': 'bulk-edit', class: 'btn--primary js-bulkEdit is-disabled' }
          { name: __('New Folder'), 'data-type': 'new-folder', class: 'btn--secondary' }
          { name: __('New Overview'), 'data-type': 'new', class: 'btn--success' }
        ]
        tableExtend:
          checkbox: true
          bindCheckbox:
            events:
              change: => @updateBulkEditButton()
            select_all: => @updateBulkEditButton()
      container: @el.closest('.content')
      veryLarge: true
      dndCallback: (e, item) =>
        items = @el.find('table > tbody > tr')
        prios = []
        prio = 0
        for item in items
          id = $(item).data('id')
          continue if !id # skip group-by header rows
          prio += 1
          prios.push [id, prio]

        @ajax(
          id:          'overview_prio'
          type:        'POST'
          url:         "#{@apiPath}/overviews_prio"
          processData: true
          data:        JSON.stringify(prios: prios)
        )
    )

    # Preload all folders so the "Folder" select lists every folder and the
    #   list can be grouped by the (full) folder path.
    App.OverviewFolder.fetchFull(=>
      @genericController.render()
    )

  show: (params) =>
    for key, value of params
      if key isnt 'el' && key isnt 'shown' && key isnt 'match'
        @[key] = value

    @genericController.paginate(@page || 1, params)

  selectedIds: =>
    ids = []
    @$('[name="bulk"]:checked').each((_index, element) ->
      ids.push parseInt($(element).val(), 10)
    )
    ids

  # Reflect the current selection on the bulk-edit button (count + enabled
  #   state). The button is rendered by the generic index, so it is updated in
  #   place rather than re-rendered.
  updateBulkEditButton: =>
    button = @$('[data-type=bulk-edit]')
    return if !button.length

    count = @selectedIds().length
    label = App.i18n.translateContent(@bulkEditLabel)
    label = "#{label} (#{count})" if count > 0
    button.text(label)
    button.toggleClass('is-disabled', count is 0)

  bulkEdit: (e) =>
    e.preventDefault()

    ids = @selectedIds()
    if _.isEmpty(ids)
      @notify(
        type: 'error'
        msg:  __('Please select at least one overview.')
      )
      return

    new App.OverviewBulkEdit(
      overviewIds: ids
      container:   @el.closest('.content')
      callback:    =>
        @$('[name="bulk"]:checked, [name="bulk_all"]:checked').prop('checked', false)
        @updateBulkEditButton()
    )

  newFolder: (e) =>
    e?.preventDefault()
    new App.ControllerGenericNew(
      genericObject: 'OverviewFolder'
      pageData:
        object: __('Folder')
      container: @el.closest('.content')
      callback:  @reloadFolders
    )

  editFolder: (id, e) =>
    e?.preventDefault()
    new App.ControllerGenericEdit(
      id:            id
      genericObject: 'OverviewFolder'
      pageData:
        object: __('Folder')
      container: @el.closest('.content')
      callback:  @reloadFolders
    )

  deleteFolder: (id, e) =>
    e?.preventDefault()
    new App.ControllerGenericDestroyConfirm(
      item:      App.OverviewFolder.find(id)
      container: @el.closest('.content')
      callback:  @reloadFolders
    )

  # Refresh the cached folders and re-render the overview list after a folder
  #   was created, changed or deleted.
  reloadFolders: =>
    App.OverviewFolder.fetchFull(
      => @genericController.render()
      clear: true
    )

App.Config.set('Overview', { prio: 2300, name: __('Overviews'), parent: '#manage', target: '#manage/overviews', controller: Overview, permission: ['admin.overview'] }, 'NavBarAdmin')
