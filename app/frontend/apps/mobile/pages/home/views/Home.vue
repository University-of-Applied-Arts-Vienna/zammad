<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonInputSearch from '#shared/components/CommonInputSearch/CommonInputSearch.vue'
import { useSessionStore } from '#shared/stores/session.ts'

import CommonSectionMenu from '#mobile/components/CommonSectionMenu/CommonSectionMenu.vue'
import type { MenuItem } from '#mobile/components/CommonSectionMenu/index.ts'
import CommonTicketCreateLink from '#mobile/components/CommonTicketCreateLink/CommonTicketCreateLink.vue'
import { useTicketOverviews } from '#mobile/entities/ticket/composables/useTicketOverviews.ts'

const IS_DEV = import.meta.env.DEV

const session = useSessionStore()

const menu: MenuItem[] = [
  {
    type: 'link',
    link: '/tickets/view',
    label: __('Ticket overviews'),
    icon: { name: 'all-tickets', size: 'base' },
    iconBg: 'bg-pink',
    permission: ['ticket.agent', 'ticket.customer'],
  },
  // Cannot inline import.meta here, Vite fails
  ...(IS_DEV
    ? [
        {
          type: 'link' as const,
          link: '/playground',
          label: 'Playground',
          icon: { name: 'settings', size: 'small' as const },
          iconBg: 'bg-orange',
        },
      ]
    : []),
]

const overviews = useTicketOverviews()

const buildOverviewItem = (
  overview: (typeof overviews.includedOverviews)[number],
): MenuItem => ({
  type: 'link',
  link: `/tickets/view/${overview.link}`,
  label: overview.name,
  information: overview.ticketCount,
})

const overviewFolderPath = (
  overview: (typeof overviews.includedOverviews)[number],
): string[] | undefined =>
  overview.folderId ? overviews.folderPathById[overview.folderId] : undefined

// Favorites that do not sit inside a (visible) folder are shown at the top.
const rootOverviewItems = computed<MenuItem[]>(() => {
  if (overviews.loading) return []

  return overviews.includedOverviews
    .filter((overview) => !overviewFolderPath(overview))
    .map(buildOverviewItem)
})

// Favorites that live inside a folder are grouped under their folder path.
const folderOverviewGroups = computed<{ path: string; items: MenuItem[] }[]>(() => {
  if (overviews.loading) return []

  const groups = new Map<string, { path: string; items: MenuItem[] }>()

  overviews.includedOverviews.forEach((overview) => {
    const path = overviewFolderPath(overview)
    if (!path) return

    const key = path.join(' / ')
    if (!groups.has(key)) groups.set(key, { path: key, items: [] })
    groups.get(key)!.items.push(buildOverviewItem(overview))
  })

  return [...groups.values()].sort((a, b) => a.path.localeCompare(b.path))
})
</script>

<template>
  <div class="p-4">
    <CommonTicketCreateLink class="mt-1.5 mb-3" />
    <h1 class="mb-5 flex w-full items-center justify-center text-4xl font-bold">
      {{ $t('Home') }}
    </h1>
    <CommonLink :aria-label="$t('Search…')" link="/search">
      <CommonInputSearch aria-hidden="true" tabindex="-1" wrapper-class="mb-4" no-border />
    </CommonLink>
    <CommonSectionMenu :items="menu" />
    <template v-if="session.hasPermission(['ticket.agent', 'ticket.customer'])">
      <CommonSectionMenu
        :items="rootOverviewItems"
        :header-label="__('Ticket overview')"
        :action-label="__('Edit')"
        action-link="/favorite/ticket-overviews/edit"
      >
        <template v-if="overviews.loading" #before-items>
          <div class="flex w-full justify-center">
            <CommonIcon name="loading" animation="spin" />
          </div>
        </template>
      </CommonSectionMenu>
      <CommonSectionMenu
        v-for="group in folderOverviewGroups"
        :key="group.path"
        :items="group.items"
        :header-label="group.path"
      />
    </template>
  </div>
</template>
