// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { tryOnScopeDispose, watchOnce } from '@vueuse/core'
import { keyBy } from 'lodash-es'
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

import type {
  Overview,
  TicketOverviewsQuery,
  TicketOverviewUpdatesSubscription,
  TicketOverviewUpdatesSubscriptionVariables,
} from '#shared/graphql/types.ts'
import { useOverviewFoldersQuery } from '#shared/entities/ticket/graphql/queries/overviewFolders.api.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'

import { useTicketOverviewsQuery } from '#mobile/entities/ticket/graphql/queries/overviews.api.ts'
import { TicketOverviewUpdatesDocument } from '#mobile/entities/ticket/graphql/subscriptions/ticketOverviewUpdates.api.ts'

import { getTicketOverviewStorage } from '../helpers/ticketOverviewStorage.ts'

export type TicketOverview = Pick<
  Overview,
  'id' | 'name' | 'organizationShared' | 'outOfOffice' | 'folderId'
>

export const useTicketOverviewsStore = defineStore('ticketOverviews', () => {
  const ticketOverviewHandler = new QueryHandler(
    useTicketOverviewsQuery({
      withTicketCount: true,
    }),
  )

  // Updates the overviews when overviews got added, updated and/or deleted.
  ticketOverviewHandler.subscribeToMore<
    TicketOverviewUpdatesSubscriptionVariables,
    TicketOverviewUpdatesSubscription
  >({
    document: TicketOverviewUpdatesDocument,
    variables: {
      withTicketCount: true,
      ignoreUserConditions: false,
    },
    updateQuery(_, { subscriptionData }) {
      const ticketOverviews = subscriptionData.data.ticketOverviewUpdates?.ticketOverviews
      // if we return empty array here, the actual query will be aborted, because we have fetchPolicy "cache-and-network"
      // if we return existing value, it will throw an error, because "overviews" doesn't exist yet on the query result
      if (!ticketOverviews) {
        return null as unknown as TicketOverviewsQuery
      }
      return {
        ticketOverviews,
      }
    },
  })

  const overviewsRaw = ticketOverviewHandler.result()
  const overviewsLoading = ticketOverviewHandler.loadingWithoutCachedResult()

  const overviews = computed(() => {
    if (!overviewsRaw.value?.ticketOverviews) return []

    return overviewsRaw.value.ticketOverviews.filter((overview) => overview?.id)
  })

  const overviewsByKey = computed(() => keyBy(overviews.value, 'id'))

  // Folders grouping the overviews (only those visible to the current user).
  const folderHandler = new QueryHandler(useOverviewFoldersQuery({ ignoreUserConditions: false }))
  const foldersRaw = folderHandler.result()
  const folders = computed(() => foldersRaw.value?.userCurrentTicketOverviewFolders || [])
  const foldersById = computed(() => keyBy(folders.value, 'internalId'))

  // Maps a folder's internal ID to its full name path from the root, e.g.
  //   ['Team A', 'Open'].
  const folderPathById = computed<Record<number, string[]>>(() => {
    const result: Record<number, string[]> = {}

    const buildPath = (folder: (typeof folders.value)[number]): string[] => {
      if (result[folder.internalId]) return result[folder.internalId]

      const parent =
        folder.parentId && foldersById.value[folder.parentId]
          ? foldersById.value[folder.parentId]
          : undefined

      const path = parent ? [...buildPath(parent), folder.name] : [folder.name]
      result[folder.internalId] = path
      return path
    }

    folders.value.forEach(buildPath)

    return result
  })

  const storage = getTicketOverviewStorage()

  const includedIds = ref(new Set<string>(storage.getOverviews()))

  const includedOverviews = computed(() => {
    return [...includedIds.value].map((id) => overviewsByKey.value[id]).filter(Boolean)
  })

  const populateIncludeIds = (overviews: TicketOverview[]) => {
    overviews.forEach((overview) => {
      includedIds.value.add(overview.id)
    })
  }

  // Do not store overviews in local storage when loaded, fallback to query response.
  if (!includedIds.value.size) {
    if (!overviews.value.length) {
      watchOnce(overviews, populateIncludeIds)
    } else {
      populateIncludeIds(overviews.value)
    }
  }

  const updateOverviews = (overviews: TicketOverview[]) => {
    const ids = overviews.map(({ id }) => id)
    includedIds.value = new Set(ids)
  }

  tryOnScopeDispose(() => {
    ticketOverviewHandler.stop()
  })

  return {
    overviews,
    folders,
    folderPathById,
    initializing: ticketOverviewHandler.operationResult.forceDisabled.value,
    loading: overviewsLoading,
    includedOverviews,
    includedIds,
    overviewsByKey,
    updateOverviews,
  }
})
