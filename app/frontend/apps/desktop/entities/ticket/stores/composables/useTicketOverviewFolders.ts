// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import { useOverviewFoldersQuery } from '#shared/entities/ticket/graphql/queries/overviewFolders.api.ts'
import { QueryHandler, SubscriptionHandler } from '#shared/server/apollo/handler/index.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import { useUserCurrentTicketOverviewFullAttributesUpdatesSubscription } from '#desktop/entities/ticket/graphql/subscriptions/userCurrentTicketOverviewFullAttributesUpdates.api.ts'

export const useTicketOverviewFolders = () => {
  const { hasPermission } = useSessionStore()

  const hasAgentOrCustomerPermission = computed(() =>
    hasPermission(['ticket.agent', 'ticket.customer']),
  )

  const folderHandler = new QueryHandler(
    useOverviewFoldersQuery({ ignoreUserConditions: false }, () => ({
      enabled: hasAgentOrCustomerPermission.value,
    })),
  )

  const foldersRaw = folderHandler.result()

  const folders = computed(() => foldersRaw.value?.userCurrentTicketOverviewFolders || [])

  // Folder visibility, names and structure can change whenever an admin edits a
  //   folder or moves an overview. Those changes trigger the existing overview
  //   update subscription, so we reuse it to refetch the (cheap) folder list.
  const overviewUpdatesSubscription = new SubscriptionHandler(
    useUserCurrentTicketOverviewFullAttributesUpdatesSubscription(
      { ignoreUserConditions: false },
      () => ({ enabled: hasAgentOrCustomerPermission.value }),
    ),
  )

  overviewUpdatesSubscription.onResult(() => {
    if (!hasAgentOrCustomerPermission.value) return
    folderHandler.refetch()
  })

  return {
    folders,
  }
}
