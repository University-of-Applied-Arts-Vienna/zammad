class Role extends App.ControllerSubContent
  @requiredPermission: 'admin.role'
  header: __('Roles')
  events:
    'click [data-type=impersonate]': 'impersonate'

  constructor: ->
    super

    buttons = [
      { name: __('New Role'), 'data-type': 'new', class: 'btn--success' }
    ]
    if @permissionCheck('admin.user')
      buttons.unshift { name: __('Impersonate'), 'data-type': 'impersonate', class: 'btn' }

    @genericController = new App.ControllerGenericIndex(
      el: @el
      id: @id
      veryLarge: true
      genericObject: 'Role'
      defaultSortBy: 'name'
      createScreen: 'create'
      editScreen: 'edit'
      searchBar: true
      searchQuery: @search_query
      searchShortcuts: [
        { query: 'active:true', label: __('Active only') }
        { query: 'default_at_signup:true', label: __('Default at Signup') }
        { query: 'updated_at:>now-7d', label: __('Updated within last 7 days') }
      ]
      pageData:
        home: 'roles'
        object: __('Role')
        objects: __('Roles')
        searchPlaceholder: __('Search for roles')
        pagerAjax: true
        pagerBaseUrl: '#manage/roles/'
        pagerSelected: ( @page || 1 )
        pagerPerPage: 50
        navupdate: '#roles'
        notes:     [
          __('Roles are …')
        ]
        buttons: buttons
      container: @el.closest('.content')
    )

  impersonate: (e) ->
    e.preventDefault()
    new App.RoleImpersonate(
      container: @el.closest('.content')
    )

  show: (params) =>
    for key, value of params
      if key isnt 'el' && key isnt 'shown' && key isnt 'match'
        @[key] = value

    @genericController.paginate(@page || 1, params)

class App.RoleImpersonate extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: __('Impersonate')
  head: __('Impersonate')
  shown: false

  constructor: ->
    super

    @ajax(
      id:    'impersonator'
      type:  'GET'
      url:   "#{@apiPath}/sessions/impersonator"
      success: (data) =>
        @data = data
        @render()
    )

  content: ->
    @controller = new App.ControllerForm(
      model:
        configure_attributes: [
          { name: 'role_ids',  display: __('Roles'),      tag: 'column_select', multiple: true, null: false, options: ({ value: role.id, name: role.name } for role in @data.roles), translate: true }
          { name: 'firstname', display: __('First name'), tag: 'input', type: 'text',  limit: 100, null: false }
          { name: 'lastname',  display: __('Last name'),  tag: 'input', type: 'text',  limit: 100, null: true }
          { name: 'email',     display: __('Email'),      tag: 'input', type: 'email', limit: 100, null: false }
        ]
      params: @data.user || {}
      autofocus: true
    )

    $('<div></div>')
      .append(App.view('role/impersonate')())
      .append(@controller.form)

  onSubmit: (e) =>
    params = @formParam(e.target)
    params.role_ids = _.compact(_.flatten([params.role_ids]))

    # validate form using HTML5 validity check
    element = $(e.target).closest('form').get(0)
    if element && element.reportValidity && !element.reportValidity()
      return

    @formDisable(e)
    @ajax(
      id:          'impersonate'
      type:        'POST'
      url:         "#{@apiPath}/sessions/impersonate"
      data:        JSON.stringify(params)
      processData: true
      success:     (data) =>
        @disconnectClient()
        $('#app').hide().attr('style', 'display: none!important')
        App.Auth._logout(false)
        location = "#{window.location.protocol}//#{window.location.host}#{data.location}"
        @windowReload(undefined, location)
      error: (xhr) =>
        @formEnable(e)
        data = JSON.parse(xhr.responseText)
        @showAlert(data?.error_human || data?.error || __('The impersonation could not be started.'))
    )

App.Config.set('Role', { prio: 1600, name: __('Roles'), parent: '#manage', target: '#manage/roles', controller: Role, permission: ['admin.role'] }, 'NavBarAdmin')
