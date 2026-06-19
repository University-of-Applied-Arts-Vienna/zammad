class Overviews extends App.ControllerSubContent
  @requiredPermission: 'user_preferences.overview_sorting'
  header: __('Order of Overviews')

  events:
    'click .js-reset': 'reset'

  constructor: ->
    super
    @fetch()

  fetch: (refreshSidebar = false) =>
    @ajax(
      type:        'GET'
      url:         "#{App.Config.get('api_path')}/user_overview_sortings"
      processData: true
      success:     (data) =>
        @overviews              = data.overviews or []
        @folders                = data.folders or []
        @overviewSortings       = data.overview_sortings or []
        @overviewFolderSortings = data.overview_folder_sortings or []

        # keep the globally shared collections (used by the agent sidebar) in sync
        App.UserOverviewSorting.refresh(@overviewSortings, { clear: true })
        App.UserOverviewFolderSorting.refresh(@overviewFolderSortings, { clear: true })

        @render()

        # re-render the agent overview sidebar so it reflects the new order
        App.OverviewIndexCollection.trigger() if refreshSidebar
    )

  render: =>
    nodes = @buildTree()

    @html App.view('profile/overviews')(
      treeHtml: @renderNodes(nodes)
      hasItems: nodes.length > 0
    )

    @initSortable()

  # Builds the same folder/overview tree the agent sidebar shows, ordered by the
  #   user's personal order (falling back to the admin order).
  buildTree: =>
    visibleFolderIds = {}
    visibleFolderIds[folder.id] = true for folder in @folders

    foldersByParent = {}
    for folder in @folders
      parentId = if folder.parent_id && visibleFolderIds[folder.parent_id] then folder.parent_id else 0
      (foldersByParent[parentId] ||= []).push(folder)

    overviewsByFolder = {}
    for overview in @overviews
      folderId = if overview.folder_id && visibleFolderIds[overview.folder_id] then overview.folder_id else 0
      (overviewsByFolder[folderId] ||= []).push(overview)

    build = (parentId) =>
      nodes = []
      for folder in (foldersByParent[parentId] or [])
        nodes.push(kind: 'folder', id: folder.id, name: folder.name, prio: @folderPrio(folder), children: build(folder.id))
      for overview in (overviewsByFolder[parentId] or [])
        nodes.push(kind: 'overview', id: overview.id, prio: @overviewPrio(overview), overview: overview)
      nodes.sort((a, b) -> a.prio - b.prio)
      nodes

    build(0)

  overviewPrio: (overview) =>
    for sorting in @overviewSortings
      return sorting.prio if sorting.overview_id is overview.id
    overview.prio + 9999

  folderPrio: (folder) =>
    for sorting in @overviewFolderSortings
      return sorting.prio if sorting.overview_folder_id is folder.id
    folder.prio + 9999

  renderNodes: (nodes) =>
    html = ''
    for node in nodes
      if node.kind is 'folder'
        html += App.view('profile/overview_sorting_folder')(
          id:           node.id
          name:         node.name
          childrenHtml: @renderNodes(node.children)
        )
      else
        html += App.view('profile/overview_sorting_overview')(
          overview: node.overview
        )
    html

  initSortable: =>
    sortables = @$('.js-sortable')

    sortables.sortable(
      items:                '> li'
      tolerance:            'pointer'
      distance:             8
      opacity:              0.6
      cursor:               'move'
      forcePlaceholderSize: true
      placeholder:          'overviewSortItem-placeholder'
      update:               @onSortUpdate
    )

    # Each list reorders only its own direct children: stop a mousedown inside a
    #   nested list from also starting a drag in the parent list.
    sortables.each((i, ul) -> $(ul).on('mousedown', (e) -> e.stopPropagation()))

  onSortUpdate: (e) =>
    # nested lists trigger one update each; only handle the innermost one
    e.stopPropagation()
    @saveOrder()

  collectEntries: (ul) =>
    entries = []
    ul.children('li').each((i, li) =>
      $li = $(li)
      entries.push(type: $li.data('type'), id: $li.data('id'))
      childUl = $li.children('ul.js-sortable').first()
      entries = entries.concat(@collectEntries(childUl)) if childUl.length
    )
    entries

  saveOrder: =>
    entries = @collectEntries(@$('.js-overviewSortRoot').first())

    # never POST an empty order from a drag — that would clear the personal order
    return if !entries.length

    @ajax(
      id:          'user_overview_sortings_prio'
      type:        'POST'
      url:         "#{@apiPath}/user_overview_sortings_prio"
      processData: true
      data:        JSON.stringify(entries: entries)
      success:     => @fetch(true)
    )

  reset: (e) =>
    e.preventDefault()

    @ajax(
      id:          'user_overview_sortings_prio'
      type:        'POST'
      url:         "#{@apiPath}/user_overview_sortings_prio"
      processData: true
      data:        JSON.stringify(reset: true)
      success:     =>
        @notify
          type: 'success'
          msg:  __('Personal overview order was reset.')
        @fetch(true)
    )

App.Config.set('Overviews', { prio: 2900, name: __('Overviews'), parent: '#profile', target: '#profile/overviews', controller: Overviews, permission: ['user_preferences.overview_sorting'] }, 'NavBarProfile')
