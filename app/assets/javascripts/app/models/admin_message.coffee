class App.AdminMessage extends App.Model
  @configure 'AdminMessage', 'message', 'start_at', 'end_at', 'group_ids', 'active'
  @extend Spine.Model.Ajax
  @url = @apiPath + '/admin_messages'
  @configure_attributes = [
    { name: 'message',    display: __('Message'), tag: 'richtext', null: false, type: 'textonly', no_images: true, limit: 5000, help: __('Shown as a warning banner at the top of Zammad while the message is active.') },
    { name: 'start_at',   display: __('Start'),   tag: 'datetime', null: false },
    { name: 'end_at',     display: __('End'),     tag: 'datetime', null: false },
    { name: 'group_ids',  display: __('Groups'),  tag: 'column_select', relation: 'Group', null: true, unsortable: true, display_full_name: true, help: __('Leave empty to show the message to all users. If groups are selected, only agents with access to those groups will see it.') },
    { name: 'active',     display: __('Active'),  tag: 'active', default: true },
    { name: 'created_at', display: __('Created'), tag: 'datetime', readonly: 1 },
    { name: 'updated_at', display: __('Updated'), tag: 'datetime', readonly: 1 },
  ]
  @configure_delete = true
  @configure_overview = [
    'message',
    'start_at',
    'end_at',
    'active',
  ]

  @description = __('''
Admin Messages are shown as warning banners at the top of Zammad during a defined time window and are also delivered as a notification. You can target all users or only the agents of specific groups.
''')
