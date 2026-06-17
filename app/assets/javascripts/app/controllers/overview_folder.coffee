class OverviewFolder extends App.ControllerSubContent
  @requiredPermission: 'admin.overview'
  header: __('Overview Folders')
  constructor: ->
    super

    @genericController = new App.ControllerGenericIndex(
      el: @el
      id: @id
      genericObject: 'OverviewFolder'
      defaultSortBy: 'prio'
      searchBar: true
      searchQuery: @search_query
      pageData:
        home: 'overview_folders'
        object: __('Overview Folder')
        objects: __('Overview Folders')
        searchPlaceholder: __('Search for overview folders')
        pagerAjax: true
        pagerBaseUrl: '#manage/overview_folders/'
        pagerSelected: ( @page || 1 )
        pagerPerPage: 50
        navupdate: '#overview_folders'
        buttons: [
          { name: __('New Folder'), 'data-type': 'new', class: 'btn--success' }
        ]
      container: @el.closest('.content')
      veryLarge: true
      dndCallback: (e, item) =>
        items = @el.find('table > tbody > tr')
        prios = []
        prio = 0
        for item in items
          id = $(item).data('id')
          continue if !id
          prio += 1
          prios.push [id, prio]

        @ajax(
          id:          'overview_folder_prio'
          type:        'POST'
          url:         "#{@apiPath}/overview_folders_prio"
          processData: true
          data:        JSON.stringify(prios: prios)
        )
    )

  show: (params) =>
    for key, value of params
      if key isnt 'el' && key isnt 'shown' && key isnt 'match'
        @[key] = value

    @genericController.paginate(@page || 1, params)

App.Config.set('OverviewFolder', { prio: 2310, name: __('Overview Folders'), parent: '#manage', target: '#manage/overview_folders', controller: OverviewFolder, permission: ['admin.overview'] }, 'NavBarAdmin')
