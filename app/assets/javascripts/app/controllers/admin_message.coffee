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
      pageData:
        home: 'admin_messages'
        object: __('Admin Message')
        objects: __('Admin Messages')
        navupdate: '#admin_messages'
        buttons: [
          { name: __('New Admin Message'), 'data-type': 'new', class: 'btn--success' }
        ]
      container: @el.closest('.content')
    )

App.Config.set('AdminMessage', { prio: 3650, name: __('Admin Messages'), parent: '#system', target: '#system/admin_messages', controller: AdminMessage, permission: ['admin.message'] }, 'NavBarAdmin')
