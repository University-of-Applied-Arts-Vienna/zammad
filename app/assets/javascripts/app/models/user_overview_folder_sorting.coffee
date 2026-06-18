class App.UserOverviewFolderSorting extends App.Model
  @configure 'UserOverviewFolderSorting', 'user_id', 'overview_folder_id', 'prio'
  @configure_attributes = [
    { name: 'user_id', display: __('User'), tag: 'select', multiple: false, null: false, relation: 'User', translate: true },
    { name: 'overview_folder_id', display: __('Folder'), tag: 'select', multiple: false, null: false, relation: 'OverviewFolder', translate: true },
    { name: 'prio', display: __('Prio'), readonly: 1 },
  ]
