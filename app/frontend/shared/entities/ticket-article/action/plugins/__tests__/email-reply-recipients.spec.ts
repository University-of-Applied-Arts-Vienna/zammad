// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { TicketArticle } from '#shared/entities/ticket/types.ts'
import { EnumTicketArticleSenderName } from '#shared/graphql/types.ts'
import type { ConfigList } from '#shared/types/store.ts'

import { replyToEmail } from '../email/reply.ts'

import { createTicket, createTicketArticle } from './utils.ts'

import type { TicketArticlePerformOptions } from '../types.ts'

const ownAddress = { emailAddress: 'group-b@example.com', isSystemAddress: true }
const foreignAddress = { emailAddress: 'group-a@example.com', isSystemAddress: true }
const customerAddress = { emailAddress: 'customer@example.com', isSystemAddress: false }

const addresses = (...parsed: { emailAddress: string; isSystemAddress: boolean }[]) => ({
  raw: parsed.map((address) => address.emailAddress).join(', '),
  parsed,
})

const reply = async (article: TicketArticle, all = false) => {
  const ticket = createTicket({
    group: { emailAddress: { name: 'Group B', emailAddress: ownAddress.emailAddress } },
  })
  const openReplyForm = vi.fn()
  const options = {
    openReplyForm,
    getNewArticleBody: () => '',
  } as unknown as TicketArticlePerformOptions

  await replyToEmail(ticket, article, options, {} as ConfigList, all)

  return openReplyForm.mock.calls[0][0]
}

const createEmailArticle = (defaults: Parameters<typeof createTicketArticle>[0]) =>
  createTicketArticle({
    type: { name: 'email' },
    sender: { name: EnumTicketArticleSenderName.Agent },
    replyTo: null,
    cc: null,
    ...defaults,
  }) as TicketArticle

describe('replyToEmail recipients', () => {
  it('answers another group which emailed the address of the ticket group', async () => {
    const article = createEmailArticle({
      from: addresses(foreignAddress),
      to: addresses(ownAddress),
    })

    expect(await reply(article)).toEqual(
      expect.objectContaining({ to: [foreignAddress.emailAddress] }),
    )
  })

  it('keeps the other group when replying to all', async () => {
    const article = createEmailArticle({
      from: addresses(foreignAddress),
      to: addresses(ownAddress),
      cc: addresses(customerAddress),
    })

    expect(await reply(article, true)).toEqual(
      expect.objectContaining({
        to: [foreignAddress.emailAddress],
        cc: [customerAddress.emailAddress],
      }),
    )
  })

  it('answers the recipient of a mail the ticket group sent', async () => {
    const article = createEmailArticle({
      from: addresses(ownAddress),
      to: addresses(customerAddress),
    })

    expect(await reply(article)).toEqual(
      expect.objectContaining({ to: [customerAddress.emailAddress] }),
    )
  })

  it('does not answer a system address which did not email the ticket group', async () => {
    const article = createEmailArticle({
      from: addresses(foreignAddress),
      to: addresses(customerAddress),
    })

    expect(await reply(article)).toEqual(
      expect.objectContaining({ to: [customerAddress.emailAddress] }),
    )
  })
})
