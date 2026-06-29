class CoreWorkflow extends App.ControllerSubContent
  @requiredPermission: 'admin.core_workflow'
  header: __('Core Workflows')
  constructor: ->
    super

    @setAttributes()

    container = @el.closest('.content')
    @folderMenu = new App.AdminFolderMenu(
      targetModel: 'CoreWorkflow'
      container:   container
      onChange:    => @genericController?.render()
    )

    @genericController = new App.ControllerGenericIndex(@folderMenu.decorateConfig(
      el: @el
      id: @id
      genericObject: 'CoreWorkflow'
      defaultSortBy: 'priority, name'
      searchBar: true
      searchQuery: @search_query
      pageData:
        home: 'core_workflow'
        object: __('Workflow')
        objects: __('Workflows')
        searchPlaceholder: __('Search for workflows')
        pagerAjax: true
        pagerBaseUrl: '#manage/core_workflow/'
        pagerSelected: ( @page || 1 )
        pagerPerPage: 50
        navupdate: '#core_workflow'
        buttons: [
          { name: __('New Workflow'), 'data-type': 'new', class: 'btn--success' }
        ]
      container: container
      veryLarge: true
      handlers: [
        App.FormHandlerAdminCoreWorkflow.run
      ]
    ))

    @folderMenu.preload(=> @genericController.render())

  show: (params) =>
    for key, value of params
      if key isnt 'el' && key isnt 'shown' && key isnt 'match'
        @[key] = value

    @genericController.paginate(@page || 1, params)

  setAttributes: ->
    for field in App.CoreWorkflow.configure_attributes
      if field.name is 'object'
        field.options = {}
        for value in App.FormHandlerCoreWorkflow.getObjects()
          field.options[value] = value
      else if field.name is 'preferences::screen'
        field.options = {}
        for value in App.FormHandlerCoreWorkflow.getScreens()
          field.options[value] = @screen2displayName(value)

  screen2displayName: (screen) ->
    mapping = {
      create: __('Creation mask'),
      create_middle: __('Creation mask'),
      edit: __('Edit mask'),
      overview_bulk: __('Overview bulk mask'),
    }
    return mapping[screen] || screen

App.Config.set('CoreWorkflowObject', { prio: 1750, parent: '#system', name: 'Core Workflows', target: '#system/core_workflow', controller: CoreWorkflow, permission: ['admin.core_workflow'] }, 'NavBarAdmin')
