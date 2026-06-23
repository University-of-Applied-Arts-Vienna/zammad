class AdminMessage extends App.ControllerSubContent
  @requiredPermission: 'admin.message'
  header: __('Admin Messages')

  constructor: ->
    super

    @genericController = new App.ControllerGenericIndex(
      el: @el
      id: @id
      genericObject: 'AdminMessage'
      defaultSortBy: 'start_at'
      defaultOrder: 'DESC'
      searchBar: true
      searchQuery: @search_query
      pageData:
        home: 'admin_messages'
        object: __('Admin Message')
        objects: __('Admin Messages')
        searchPlaceholder: __('Search for admin messages')
        pagerAjax: true
        pagerBaseUrl: '#system/admin_messages/'
        pagerSelected: ( @page || 1 )
        pagerPerPage: 50
        navupdate: '#admin_messages'
        buttons: [
          { name: __('New Admin Message'), 'data-type': 'new', class: 'btn--success' }
        ]
      container: @el.closest('.content')
    )

  show: (params) =>
    for key, value of params
      if key isnt 'el' && key isnt 'shown' && key isnt 'match'
        @[key] = value

    @genericController.paginate(@page || 1, params)

App.Config.set('AdminMessage', { prio: 3650, name: __('Admin Messages'), parent: '#system', target: '#system/admin_messages', controller: AdminMessage, permission: ['admin.message'] }, 'NavBarAdmin')
