// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, onUnmounted, watch } from 'vue'

import { QueryHandler, SubscriptionHandler } from '#shared/server/apollo/handler/index.ts'

import { useCurrentAdminMessagesQuery } from '#desktop/entities/admin-message/graphql/queries/currentAdminMessages.api.ts'
import { useAdminMessageUpdatesSubscription } from '#desktop/entities/admin-message/graphql/subscriptions/adminMessageUpdates.api.ts'

export const useAdminMessages = () => {
  const query = new QueryHandler(useCurrentAdminMessagesQuery())
  const result = query.result()

  const messages = computed(() => result.value?.currentAdminMessages ?? [])

  // Refetch whenever the server signals a change: create/update/destroy, or a
  // message entering its time window (triggered by the scheduler).
  const subscription = new SubscriptionHandler(useAdminMessageUpdatesSubscription())
  subscription.onResult(() => {
    query.refetch()
  })

  // A message has no database change when its time window ends, so refetch once
  // the earliest currently-shown message expires to make the banner disappear.
  let expiryTimeout: ReturnType<typeof setTimeout> | undefined

  const clearExpiry = () => {
    if (expiryTimeout) {
      clearTimeout(expiryTimeout)
      expiryTimeout = undefined
    }
  }

  const scheduleExpiry = () => {
    clearExpiry()

    const ends = messages.value
      .map((message) => new Date(message.endAt).getTime())
      .filter((time) => !Number.isNaN(time))

    if (!ends.length) return

    const timeout = Math.min(...ends) - Date.now() + 1000
    if (timeout <= 0) return

    // Cap to avoid scheduling absurdly long timers.
    expiryTimeout = setTimeout(() => query.refetch(), Math.min(timeout, 24 * 60 * 60 * 1000))
  }

  watch(messages, scheduleExpiry, { immediate: true })

  onUnmounted(clearExpiry)

  return { messages }
}
