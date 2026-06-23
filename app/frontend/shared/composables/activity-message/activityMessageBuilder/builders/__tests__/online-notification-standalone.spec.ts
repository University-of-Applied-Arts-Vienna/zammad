// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import builder from '../online-notification-standalone.ts'

describe('online notification standalone activity message builder', () => {
  it('renders an admin message as plain text', () => {
    const metaObject = {
      data: {
        __typename: 'OnlineNotificationStandaloneAdminMessageData',
        message: '<p>Scheduled <b>maintenance</b> tonight</p>',
        adminMessageId: 1,
      },
    }

    expect(builder.messageText('admin_message', '', metaObject as never)).toBe(
      'Scheduled maintenance tonight',
    )
  })

  it('renders the bulk job summary', () => {
    const metaObject = {
      data: {
        __typename: 'OnlineNotificationStandaloneBulkJobData',
        total: 5,
        failedCount: 2,
      },
    }

    expect(builder.messageText('bulk_job', '', metaObject as never)).toContain('5')
  })
})
