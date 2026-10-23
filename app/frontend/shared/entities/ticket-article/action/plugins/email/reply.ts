// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { uniq } from 'lodash-es'

import type { TicketById, TicketArticle } from '#shared/entities/ticket/types.ts'
import { useTicketArticleEmailForwardReplyMutation } from '#shared/entities/ticket-article/graphql/mutations/ticketArticleEmailForwardReply.api.ts'
import { EnumTicketArticleSenderName, type AddressesField } from '#shared/graphql/types.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'
import type { ConfigList } from '#shared/types/store.ts'

import { getArticleSelection, getReplyQuoteHeader } from './selection.ts'

import type { TicketArticlePerformOptions } from '../types.ts'

const getEmailAddresses = (field?: Maybe<AddressesField>, allowedSystemAddress?: string) => {
  if (!field) return []
  const addresses = field.parsed?.filter(
    (email): email is { emailAddress: string; isSystemAddress: boolean } => !!email.emailAddress,
  )
  if (addresses?.length) {
    return addresses
      .filter(
        (address) =>
          !address.isSystemAddress || address.emailAddress.toLowerCase() === allowedSystemAddress,
      )
      .map((address) => address.emailAddress)
  }
  return []
}

// The address of another group, which emailed the address of the ticket's group (a
//   request between groups). It is answered although it is a system address.
const getForeignGroupAddress = (ticket: TicketById, article: TicketArticle) => {
  const ownAddress = ticket.group.emailAddress?.emailAddress?.toLowerCase()
  if (!ownAddress) return undefined

  const isOwnAddress = (address: { emailAddress?: Maybe<string> }) =>
    address.emailAddress?.toLowerCase() === ownAddress

  const fromAddresses = article.from?.parsed || []
  if (fromAddresses.some(isOwnAddress)) return undefined

  const recipientAddresses = [...(article.to?.parsed || []), ...(article.cc?.parsed || [])]
  if (!recipientAddresses.some(isOwnAddress)) return undefined

  return fromAddresses
    .find((address) => address.isSystemAddress && address.emailAddress)
    ?.emailAddress?.toLowerCase()
}

const getEmptyArticle = (article: TicketArticle) => ({
  articleType: 'email',
  subtype: 'reply',
  to: [] as string[],
  cc: [] as string[],
  subject: undefined as string | undefined,
  body: '',
  inReplyTo: article.messageId,
})

const getPhoneArticle = (ticket: TicketById, article: TicketArticle) => {
  const newArticle = getEmptyArticle(article)

  const sender = article.sender?.name

  // the article we are replying to is an outbound call
  if (sender === EnumTicketArticleSenderName.Agent) {
    if (article.to?.raw.includes('@')) {
      newArticle.to = getEmailAddresses(article.to)
    }
    // the article we are replying to is an incoming call
  } else if (article.from?.raw.includes('@')) {
    newArticle.to = getEmailAddresses(article.from)
  }
  // if sender is customer but in article.from is no email, try to get
  // customers email via customer user
  if (!newArticle.to.length || newArticle.to.every((r) => !r.includes('@')))
    newArticle.to = ticket.customer.email ? [ticket.customer.email] : []
  return newArticle
}

const areAddressesSystem = (address?: Maybe<AddressesField>) => {
  if (!address?.parsed) return false
  return address.parsed.some((address) => address.isSystemAddress)
}

const prepareEmails = (emailsSeen: Set<string>, emails: string[], newEmail?: string[]) => {
  const filteredEmails = emails
    .map((email) => email.toLowerCase())
    .filter((email) => {
      if (!email || emailsSeen.has(email)) return false
      return true
    })

  if (newEmail) {
    filteredEmails.push(...newEmail)
  }

  filteredEmails.forEach((email) => emailsSeen.add(email))

  // see https://github.com/zammad/zammad/issues/2154
  return uniq(filteredEmails).map((a) => a.replace(/'(\S+@\S+\.\S+)'/, '$1'))
}

const prepareAllEmails = (
  emailsSeen: Set<string>,
  article: TicketArticle,
  newArticle: ReturnType<typeof getEmptyArticle>,
  foreignGroupAddress?: string,
) => {
  if (article.from) {
    newArticle.to = prepareEmails(
      emailsSeen,
      getEmailAddresses(article.from, foreignGroupAddress),
      newArticle.to,
    )
  }

  if (article.to) {
    newArticle.to = prepareEmails(
      emailsSeen,
      getEmailAddresses(article.to, foreignGroupAddress),
      newArticle.to,
    )
  }

  if (article.cc) {
    newArticle.cc = prepareEmails(
      emailsSeen,
      getEmailAddresses(article.cc, foreignGroupAddress),
      newArticle.cc,
    )
  }
}

// app/assets/javascripts/app/lib/app_post/utils.coffee:1236
const getRecipientArticle = (ticket: TicketById, article: TicketArticle, all = false) => {
  const type = article.type?.name

  if (type === 'phone') {
    return getPhoneArticle(ticket, article)
  }

  const newArticle = getEmptyArticle(article)

  const sender = article.sender?.name

  const senderIsSystem = areAddressesSystem(article.from)
  const recipientIsSystem = areAddressesSystem(article.to)

  const senderEmail = article.author.email
  const isSystem =
    !recipientIsSystem &&
    sender === EnumTicketArticleSenderName.Agent &&
    senderEmail &&
    article.from?.parsed?.some((address) =>
      address.emailAddress?.toLowerCase().includes(senderEmail),
    )

  const foreignGroupAddress = senderIsSystem ? getForeignGroupAddress(ticket, article) : undefined

  if (foreignGroupAddress) {
    newArticle.to = getEmailAddresses(article.replyTo || article.from, foreignGroupAddress)
  } else if (senderIsSystem) {
    newArticle.to = getEmailAddresses(article.replyTo || article.to)
  }
  // sender is agent - sent via system
  else if (isSystem) {
    newArticle.to = getEmailAddresses(article.to)
  }
  // sender was regular customer
  else {
    newArticle.to = getEmailAddresses(article.replyTo || article.from)
    if (!newArticle.to.length || newArticle.to.every((r) => !r.includes('@')))
      newArticle.to = senderEmail ? [senderEmail] : []
  }

  const emailsSeen = new Set<string>()

  if (newArticle.to.length) {
    newArticle.to = prepareEmails(emailsSeen, newArticle.to)
  }

  if (!all) {
    return newArticle
  }

  prepareAllEmails(emailsSeen, article, newArticle, foreignGroupAddress)

  return newArticle
}

const quotableAuthorNameMutation = new MutationHandler(
  useTicketArticleEmailForwardReplyMutation({}),
  {
    errorShowNotification: false,
  },
)

// The citation name follows the configured email sender format and is computed
//   server side, shared with the forwarded quote header. On failure the plain
//   author name serves as fallback.
const fetchQuotableAuthorName = async (article: TicketArticle) => {
  try {
    const result = await quotableAuthorNameMutation.send({ articleId: article.id })
    return result?.ticketArticleEmailForwardReply?.quotableAuthorName
  } catch {
    return undefined
  }
}

export const replyToEmail = async (
  ticket: TicketById,
  article: TicketArticle,
  options: TicketArticlePerformOptions,
  config: ConfigList,
  all = false,
) => {
  const newArticle = getRecipientArticle(ticket, article, all)

  if (config.ui_ticket_zoom_article_email_subject) {
    newArticle.subject = article.subject || ticket.title
  }

  // eslint-disable-next-line prefer-const
  let { content: selection, full } = getArticleSelection(options.selection, article, config)

  if (selection) {
    const authorName = config.ui_ticket_zoom_article_email_full_quote_header
      ? await fetchQuotableAuthorName(article)
      : undefined
    const header = getReplyQuoteHeader(config, article, authorName)
    // data-full will be removed by the backend, it's used only for siganture handling
    selection = `${full ? '' : '<p><br><br></p>'}<blockquote type="cite" ${
      full ? 'data-marker="signature-before"' : ''
    }>${header}${selection}</blockquote>`
  }

  const currentBody = options.getNewArticleBody('text/html')
  const body =
    (selection || '') + (currentBody && selection ? `<p></p>${currentBody}` : currentBody)

  options.openReplyForm({
    ...newArticle,
    subtype: 'reply',
    body,
  })
}
